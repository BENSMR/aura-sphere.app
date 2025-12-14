# Desktop Sidebar Navigation Documentation

## Overview

The desktop sidebar provides a professional, feature-rich navigation system for desktop users of AuraSphere Pro. It includes:

- **Role-based menu visibility** (owner/employee)
- **Conditional menu items** (e.g., inventory based on usage)
- **Collapsible advanced section** for advanced features
- **Icon-based visual design** with descriptions
- **Active route highlighting**
- **Search functionality** support
- **Fully accessible** (ARIA labels, keyboard navigation)

## Files

### Core Configuration
- `src/navigation/desktopSidebar.js` — Menu structure and utilities
- `src/components/DesktopSidebar.jsx` — React component implementation

### Documentation
- `DESKTOP_SIDEBAR_EXAMPLES.js` — 10 complete implementation examples
- `DESKTOP_SIDEBAR_DOCUMENTATION.md` — This file

## Quick Start

### 1. Basic Usage

```jsx
import DesktopSidebar from './components/DesktopSidebar';
import { useNavigate } from 'react-router-dom';

function Layout() {
  const navigate = useNavigate();
  
  return (
    <div className="app-layout">
      <DesktopSidebar
        hasUsedInventory={true}
        onNavigate={(path) => navigate(path)}
      />
      <main className="main-content">
        {/* Page content */}
      </main>
    </div>
  );
}
```

### 2. With Advanced Features Disabled

```jsx
<DesktopSidebar
  hasUsedInventory={true}
  showAdvanced={false}  // Hide advanced section
  onNavigate={(path) => navigate(path)}
/>
```

### 3. With Non-Collapsible Advanced Section

```jsx
<DesktopSidebar
  hasUsedInventory={true}
  collapsible={false}  // Always expand advanced
  onNavigate={(path) => navigate(path)}
/>
```

## Menu Structure

### Core Items (6-7 items)
These items are always visible to owners:

- **Dashboard** 📊 — Business overview and analytics
- **Clients** 👥 — Client management
- **Invoices** 📄 — Invoice management
- **Tasks** ✓ — Task tracking
- **Expenses** 💰 — Expense tracking
- **Team** 👨‍💼 — Team management
- **Inventory** 📦 — (Optional, only if `hasUsedInventory={true}`)

### Advanced Items (6 items)
Shown in a collapsible section, visible only to owners:

- **Suppliers** 🏭 — Supplier management
- **Purchase Orders** 📋 — PO management
- **Loyalty** ⭐ — Customer loyalty program
- **Wallet** 💳 — Wallet and billing
- **Alerts** 🔔 — System alerts and notifications
- **Settings** ⚙️ — Application settings

### Conditional Items
- **Inventory** — Only appears after first access (`hasUsedInventory={true}`)

## API Reference

### `getDesktopSidebar(hasUsedInventory)`

Returns sidebar structure with core and advanced sections.

**Parameters:**
- `hasUsedInventory` (boolean) — Include inventory in core menu

**Returns:**
```javascript
{
  core: [
    { name: "Dashboard", path: "/dashboard", icon: "📊", description: "..." },
    // ... other items
  ],
  advanced: [
    { name: "Suppliers", path: "/suppliers", icon: "🏭", description: "..." },
    // ... other items
  ]
}
```

**Example:**
```javascript
const { core, advanced } = getDesktopSidebar(true);
```

### `getAllSidebarItems(hasUsedInventory)`

Get all menu items as a flat array.

**Example:**
```javascript
const allItems = getAllSidebarItems(true);
// [Dashboard, Clients, Invoices, Tasks, Expenses, Team, Inventory, 
//  Suppliers, POs, Loyalty, Wallet, Alerts, Settings]
```

### `findSidebarItemByPath(path, hasUsedInventory)`

Find a menu item by its route path.

**Example:**
```javascript
const item = findSidebarItemByPath('/invoices', true);
// { name: "Invoices", path: "/invoices", icon: "📄", description: "..." }
```

### `getSidebarItemCounts(hasUsedInventory)`

Get count of menu items in each section.

**Example:**
```javascript
const counts = getSidebarItemCounts(true);
// { core: 7, advanced: 6, total: 13 }
```

### `isAdvancedMenuItem(path, hasUsedInventory)`

Check if a path is in the advanced section.

**Example:**
```javascript
const isAdvanced = isAdvancedMenuItem('/wallet', true);
// true
```

### `isCoreMenuItem(path, hasUsedInventory)`

Check if a path is in the core section.

**Example:**
```javascript
const isCore = isCoreMenuItem('/dashboard', true);
// true
```

### `getMenuSection(path, hasUsedInventory)`

Get the section a path belongs to.

**Example:**
```javascript
const section = getMenuSection('/wallet', true);
// 'advanced'
```

### `searchSidebarItems(searchTerm, hasUsedInventory)`

Search menu items by name or description.

**Example:**
```javascript
const results = searchSidebarItems('management', true);
// [Items with 'management' in name or description]
```

### `getSidebarConfig(hasUsedInventory)`

Get complete sidebar configuration with styling values.

**Example:**
```javascript
const config = getSidebarConfig(true);
// {
//   width: 280,
//   mobileBreakpoint: 768,
//   animationDuration: 300,
//   core: [...],
//   advanced: [...]
// }
```

## Component Props

### DesktopSidebar Component

```jsx
<DesktopSidebar
  hasUsedInventory={boolean}    // Default: false
  activePath={string}            // Default: current location
  onNavigate={function}          // Navigation callback
  showAdvanced={boolean}         // Default: true
  collapsible={boolean}          // Default: true
/>
```

**Props:**

| Prop | Type | Default | Description |
|------|------|---------|-------------|
| `hasUsedInventory` | boolean | false | Show inventory in core menu |
| `activePath` | string | location.pathname | Current active route |
| `onNavigate` | function | navigate() | Called when menu item clicked |
| `showAdvanced` | boolean | true | Show advanced section |
| `collapsible` | boolean | true | Allow advanced section to collapse |

## Responsive Behavior

### Desktop (>= 768px)
- Sidebar displayed on left side
- Fixed width (280px)
- Full content layout with sidebar

### Mobile (< 768px)
- Sidebar hidden
- Use `ResponsiveNavigation` component instead
- Bottom tab navigation

## Accessibility Features

✅ **Keyboard Navigation**
- Tab through menu items
- Enter/Space to activate
- Arrow keys to navigate

✅ **Screen Reader Support**
- ARIA labels on all interactive elements
- Current page indication with `aria-current="page"`
- Section labels with `aria-label`
- Expanded state with `aria-expanded`

✅ **Visual Indicators**
- Active item highlighted with color and left border
- Hover states for all interactive items
- Icon + text for clarity

## Styling

### CSS Classes

```css
/* Main container */
.desktop-sidebar { }

/* Header section */
.sidebar-header { }
.sidebar-title { }

/* Menu structure */
.sidebar-section { }
.sidebar-menu { }
.sidebar-item { }
.sidebar-link { }
.sidebar-link.active { }
.sidebar-link:hover { }

/* Icons and labels */
.sidebar-icon { }
.sidebar-name { }

/* Advanced section */
.sidebar-advanced { }
.advanced-toggle { }
.advanced-toggle.open { }
.toggle-icon { }
.advanced-menu { }
.advanced-link { }

/* Footer */
.sidebar-footer { }
.employee-notice { }

/* Main content adjustment */
.main-content { margin-left: 280px; }
```

### Styling Example

```css
.desktop-sidebar {
  width: 280px;
  background-color: #ffffff;
  border-right: 1px solid #e0e0e0;
}

.sidebar-link {
  padding: 12px 20px;
  color: #555;
}

.sidebar-link:hover {
  background-color: #f5f5f5;
}

.sidebar-link.active {
  background-color: #f0f0f0;
  border-left: 3px solid #4CAF50;
}
```

## Role-Based Behavior

### Owner
- ✅ Sees all core items
- ✅ Sees advanced section
- ✅ Can toggle advanced section
- ✅ Can access all routes

### Employee
- ✅ Sees core items (except Inventory unless used)
- ❌ Advanced section hidden
- ❌ Sees employee notice
- ❌ Cannot access advanced routes

## Integration Examples

### 1. With Route Validation

```jsx
<DesktopSidebar
  onNavigate={(path) => {
    if (canAccessRoute(role, path)) {
      navigate(path);
    } else {
      showAccessDenied();
    }
  }}
/>
```

### 2. With Active State Management

```jsx
const [activePath, setActivePath] = useState('/dashboard');

<DesktopSidebar
  activePath={activePath}
  onNavigate={(path) => {
    setActivePath(path);
    navigate(path);
  }}
/>
```

### 3. With Breadcrumbs

```jsx
const currentItem = findSidebarItemByPath(location.pathname, true);

<>
  <DesktopSidebar onNavigate={navigate} />
  <Breadcrumb item={currentItem} />
</>
```

### 4. With Search

```jsx
const [search, setSearch] = useState('');
const results = search ? searchSidebarItems(search) : [];

<>
  <SearchInput value={search} onChange={setSearch} />
  {results.length > 0 && <SearchResults items={results} />}
  <DesktopSidebar onNavigate={navigate} />
</>
```

## Conditional Features

### Inventory Menu Item

The inventory menu appears conditionally:

```jsx
// First visit: Inventory not visible
<DesktopSidebar hasUsedInventory={false} />

// After accessing: Inventory visible
<DesktopSidebar hasUsedInventory={true} />
```

Track inventory usage:

```jsx
const [hasUsedInventory, setHasUsedInventory] = useState(false);

const handleNavigate = (path) => {
  if (path === '/inventory') {
    setHasUsedInventory(true);
  }
  navigate(path);
};

<DesktopSidebar 
  hasUsedInventory={hasUsedInventory}
  onNavigate={handleNavigate}
/>
```

## Performance Optimization

### Memoization

```jsx
const MemoizedSidebar = React.memo(DesktopSidebar, (prev, next) => {
  return prev.activePath === next.activePath &&
         prev.hasUsedInventory === next.hasUsedInventory;
});
```

### Lazy Configuration

```jsx
const getMenuConfig = useMemo(
  () => getDesktopSidebar(hasUsedInventory),
  [hasUsedInventory]
);
```

## Testing

### Unit Tests

```javascript
import { 
  getDesktopSidebar,
  findSidebarItemByPath,
  isAdvancedMenuItem
} from '../navigation/desktopSidebar';

describe('desktopSidebar', () => {
  test('includes inventory when flag is true', () => {
    const { core } = getDesktopSidebar(true);
    expect(core.some(item => item.name === 'Inventory')).toBe(true);
  });
  
  test('finds item by path', () => {
    const item = findSidebarItemByPath('/invoices', true);
    expect(item.name).toBe('Invoices');
  });
  
  test('identifies advanced menu items', () => {
    expect(isAdvancedMenuItem('/wallet', true)).toBe(true);
    expect(isAdvancedMenuItem('/dashboard', true)).toBe(false);
  });
});
```

### Component Tests

```javascript
import { render, screen } from '@testing-library/react';
import DesktopSidebar from '../components/DesktopSidebar';

describe('DesktopSidebar', () => {
  test('renders core menu items', () => {
    render(<DesktopSidebar hasUsedInventory={true} />);
    expect(screen.getByText('Dashboard')).toBeInTheDocument();
  });
  
  test('shows advanced section for owners', () => {
    jest.mock('../hooks/useRole', () => ({
      useRole: () => ({ role: 'owner' })
    }));
    
    render(<DesktopSidebar showAdvanced={true} />);
    expect(screen.getByText('Advanced Features')).toBeInTheDocument();
  });
});
```

## Troubleshooting

### Sidebar not appearing

**Check:**
- Desktop viewport (>= 768px)
- Component is rendered in correct location
- CSS is imported
- Role is 'owner'

### Advanced section not collapsing

**Check:**
- `collapsible={true}` prop
- `showAdvanced={true}` prop
- User role is 'owner'
- JavaScript not blocked

### Menu item not highlighted

**Check:**
- `activePath` matches route path exactly
- `onNavigate` is updating active path
- CSS classes are applied
- Browser DevTools for CSS issues

## Next Steps

1. **Integrate** sidebar into your main layout
2. **Style** according to your design system
3. **Test** with different roles and menu items
4. **Deploy** to production

## See Also

- [Navigation.jsx](./src/components/Navigation.jsx) — Mobile navigation
- [useRole.js](./src/hooks/useRole.js) — Role detection hooks
- [mobileRoutes.js](./src/navigation/mobileRoutes.js) — Mobile routing

## Examples

See `DESKTOP_SIDEBAR_EXAMPLES.js` for 10 complete implementation examples:

1. Basic sidebar usage
2. With advanced features disabled
3. With non-collapsible advanced section
4. Direct configuration usage
5. Feature tracking (inventory)
6. Search functionality
7. Custom theming
8. Responsive design
9. Breadcrumb integration
10. Usage analytics

---

**Status:** ✅ Complete and ready to use
**Version:** 1.0
**Last Updated:** 2024
