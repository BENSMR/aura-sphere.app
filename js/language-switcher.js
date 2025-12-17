// language-switcher.js
// Works with translations.js
// Saves user preference to localStorage
// Auto-applies on load

// List of supported languages with names and flags (emoji)
const languageOptions = [
  { code: 'en', name: 'English', flag: '🇬🇧' },
  { code: 'bg', name: 'Български', flag: '🇧🇬' },
  { code: 'fr', name: 'Français', flag: '🇫🇷' },
  { code: 'de', name: 'Deutsch', flag: '🇩🇪' },
  { code: 'es', name: 'Español', flag: '🇪🇸' },
  { code: 'it', name: 'Italiano', flag: '🇮🇹' },
  { code: 'pt', name: 'Português', flag: '🇵🇹' },
  { code: 'nl', name: 'Nederlands', flag: '🇳🇱' },
  { code: 'pl', name: 'Polski', flag: '🇵🇱' },
  { code: 'sv', name: 'Svenska', flag: '🇸🇪' },
  { code: 'da', name: 'Dansk', flag: '🇩🇰' },
  { code: 'fi', name: 'Suomi', flag: '🇫🇮' },
  { code: 'el', name: 'Ελληνικά', flag: '🇬🇷' },
  { code: 'cs', name: 'Čeština', flag: '🇨🇿' },
  { code: 'hu', name: 'Magyar', flag: '🇭🇺' },
  { code: 'ro', name: 'Română', flag: '🇷🇴' },
  { code: 'ar', name: 'العربية', flag: '🇸🇦' },
  { code: 'zh', name: '中文', flag: '🇨🇳' },
  { code: 'ru', name: 'Русский', flag: '🇷🇺' }
];

// Get user's saved or detected language
function getCurrentLanguage() {
  return localStorage.getItem('aura-sphere-lang') || getUserLanguage();
}

// Apply language and save preference
function setLanguage(langCode) {
  localStorage.setItem('aura-sphere-lang', langCode);
  translateUI(langCode);
  
  // Optional: update URL for shareability (comment out if not needed)
  // const url = new URL(window.location);
  // url.searchParams.set('lang', langCode);
  // window.history.replaceState({}, '', url);
}

// Render language switcher in element with id="language-switcher"
function renderLanguageSwitcher() {
  const container = document.getElementById('language-switcher');
  if (!container) return;

  const currentLang = getCurrentLanguage();
  
  // Create select element
  const select = document.createElement('select');
  select.id = 'lang-select';
  select.style.cssText = `
    padding: 6px 12px;
    border: 1px solid #ddd;
    border-radius: 6px;
    background: white;
    font-size: 14px;
    direction: ltr;
  `;

  languageOptions.forEach(opt => {
    const option = document.createElement('option');
    option.value = opt.code;
    option.textContent = `${opt.flag} ${opt.name}`;
    option.selected = opt.code === currentLang;
    select.appendChild(option);
  });

  select.addEventListener('change', (e) => {
    setLanguage(e.target.value);
  });

  container.innerHTML = '';
  container.appendChild(select);
}

// Initialize switcher when DOM is ready
document.addEventListener('DOMContentLoaded', () => {
  // Override translateUI to use saved preference
  const savedLang = localStorage.getItem('aura-sphere-lang');
  if (savedLang && translations[savedLang]) {
    translateUI(savedLang);
  } else {
    translateUI(); // uses auto-detect
  }
  
  // Render switcher if container exists
  if (document.getElementById('language-switcher')) {
    renderLanguageSwitcher();
  }
});
