/**
 * Email notification templates for AuraSphere
 */

export const defaultEmailTemplate = `<!doctype html>
<html>
  <head>
    <meta charset="utf-8"/>
    <title>{{subject}}</title>
    <style>
      body { font-family: Arial, sans-serif; color: #111; }
      .card { border-radius: 8px; padding: 20px; background: #fff; box-shadow: 0 6px 18px rgba(0,0,0,0.06); }
      .header { display:flex; align-items:center; gap:12px; }
      .logo { width:48px; height:48px; border-radius:8px; background:#0A84FF; color:#fff; display:flex; align-items:center; justify-content:center; font-weight:bold; }
      .title { font-size:18px; font-weight:600; }
      .body { margin-top:14px; color:#333; }
      .footer { margin-top:20px; color:#777; font-size:12px; }
      .btn { display:inline-block; background:#0A84FF; color:#fff; padding:10px 14px; border-radius:6px; text-decoration:none; }
      .severity { display:inline-block; padding:4px 8px; border-radius:6px; background:#fff3cd; color:#856404; font-weight:600; }
    </style>
  </head>
  <body>
    <div class="card">
      <div class="header">
        <div class="logo">A</div>
        <div>
          <div class="title">{{subject}}</div>
          <div style="font-size:12px; color:#666;">{{subtitle}}</div>
        </div>
      </div>
      <div class="body">
        <p>{{body}}</p>
        <p><strong>Severity:</strong> <span class="severity">{{severity}}</span></p>
        <p><a class="btn" href="{{action_url}}">Open in AuraSphere</a></p>
      </div>
      <div class="footer">
        Sent by AuraSphere • <a href="https://aura-sphere.app">aura-sphere.app</a>
      </div>
    </div>
  </body>
</html>`;

/**
 * Render template with variables
 * @param template - HTML template with {{var}} placeholders
 * @param vars - Map of variable names to values
 * @returns Rendered HTML string
 */
export function renderTemplate(template: string, vars: Record<string, string>): string {
  let html = template;
  Object.entries(vars).forEach(([key, value]) => {
    html = html.replace(new RegExp(`{{${key}}}`, 'g'), value || '');
  });
  return html;
}

/**
 * Example: render alert email
 */
export function renderAlertEmail(options: {
  subject: string;
  subtitle: string;
  body: string;
  severity: 'low' | 'medium' | 'high' | 'critical';
  action_url: string;
}): string {
  return renderTemplate(defaultEmailTemplate, {
    subject: options.subject,
    subtitle: options.subtitle,
    body: options.body,
    severity: options.severity.charAt(0).toUpperCase() + options.severity.slice(1),
    action_url: options.action_url,
  });
}
