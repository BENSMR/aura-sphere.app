import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

export const dryRunInventoryChanges = functions.https.onCall(
  async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError("unauthenticated", "Must be signed in.");
    }

    const uid = context.auth.uid;
    const supplier = data.supplier || null;
    const items = Array.isArray(data.items) ? data.items : [];

    if (items.length === 0) {
      throw new functions.https.HttpsError("invalid-argument", "No items passed.");
    }

    const db = admin.firestore();

    const supplierSnap = supplier
      ? await db.collection("users").doc(uid)
          .collection("suppliers")
          .where("name", "==", supplier.trim())
          .limit(1)
          .get()
      : null;

    // Supplier diff
    const supplierChanges = {
      exists: supplierSnap && !supplierSnap.empty,
      createSupplier: supplier && supplierSnap?.empty,
      supplierId: supplierSnap?.empty ? null : supplierSnap?.docs[0].id,
    };

    const itemResults = [];

    for (const item of items) {
      const name = (item.name ?? "").trim();
      if (!name) continue;

      const sku = item.sku?.trim();

      // Match by SKU OR name
      const snap = await db.collection("users").doc(uid)
        .collection("inventory")
        .where("sku", "==", sku || "__no_sku__")
        .get();

      let match = !snap.empty ? snap.docs[0] : null;

      // fallback: match by name (soft match)
      if (!match) {
        const nameSnap = await db.collection("users").doc(uid)
          .collection("inventory")
          .where("name", "==", name)
          .limit(1)
          .get();

        if (!nameSnap.empty) match = nameSnap.docs[0];
      }

      if (match) {
        // Existing item → preview update
        const before = match.data();
        const after = {
          ...before,
          quantity: (before.quantity ?? 0) + (item.quantity ?? 0),
          costPrice: item.costPrice ?? before.costPrice,
          sellingPrice: item.sellingPrice ?? before.sellingPrice,
          lastRestockedAt: admin.firestore.Timestamp.now(),
        };

        itemResults.push({
          type: "update",
          itemId: match.id,
          before,
          after,
          warnings: [],
        });
      } else {
        // New item → preview create
        itemResults.push({
          type: "create",
          before: null,
          after: {
            name,
            sku: sku || null,
            quantity: item.quantity ?? 0,
            costPrice: item.costPrice ?? null,
            sellingPrice: item.sellingPrice ?? null,
            supplier: supplier || null,
            createdAt: admin.firestore.Timestamp.now(),
          },
          warnings: sku ? [] : ["No SKU detected"],
        });
      }
    }

    return {
      success: true,
      supplierChanges,
      itemResults,
    };
  }
);
