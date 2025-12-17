// ====================================
// AuraSphere CRM Application
// ====================================

const CRM = {
  // Initialize the app
  init() {
    this.setupEventListeners();
    this.initializeLanguageUI();
    this.loadDarkModePreference();
    console.log('✅ CRM App Initialized');
  },

  // ====================================
  // Event Listeners
  // ====================================

  setupEventListeners() {
    const closeButtons = document.querySelectorAll('.close-btn');

    // Export Modal
    const exportBtn = document.getElementById('export-btn');
    const exportModal = document.getElementById('export-modal');
    const exportPdfBtn = document.getElementById('export-pdf-btn');
    const exportCsvBtn = document.getElementById('export-csv-btn');

    if (exportBtn) {
      exportBtn.addEventListener('click', () => {
        this.openModal(exportModal);
      });
    }

    if (exportPdfBtn) {
      exportPdfBtn.addEventListener('click', () => {
        this.exportAsPDF();
      });
    }

    if (exportCsvBtn) {
      exportCsvBtn.addEventListener('click', () => {
        this.exportAsCSV();
      });
    }

    // CRM Feature Buttons
    document.getElementById('add-client-btn')?.addEventListener('click', () => this.addClient());
    document.getElementById('create-invoice-btn')?.addEventListener('click', () => this.createInvoice());
    document.getElementById('add-task-btn')?.addEventListener('click', () => this.addTask());
    document.getElementById('add-expense-btn')?.addEventListener('click', () => this.addExpense());
    document.getElementById('add-funds-btn')?.addEventListener('click', () => this.addFunds());
    document.getElementById('theme-toggle-btn')?.addEventListener('click', () => this.toggleDarkMode());
    document.getElementById('backup-btn')?.addEventListener('click', () => this.backupData());

    // Close modals when clicking outside
    window.addEventListener('click', (e) => {
      const modals = document.querySelectorAll('.modal');
      modals.forEach(modal => {
        if (e.target === modal) {
          modal.classList.remove('active');
        }
      });
    });
  },

  openModal(modal) {
    if (modal) {
      modal.classList.add('active');
    }
  },

  // ====================================
  // CRM Actions
  // ====================================

  addClient() {
    const name = prompt('Enter client name:');
    if (name) {
      const clientsList = document.getElementById('clients-list');
      const client = document.createElement('div');
      client.className = 'client-item';
      client.innerHTML = `
        <p><strong>${name}</strong></p>
        <small>${new Date().toLocaleDateString()}</small>
      `;
      clientsList.appendChild(client);
      console.log('✅ Client added:', name);
    }
  },

  createInvoice() {
    const invoiceNum = Math.floor(Math.random() * 10000);
    const invoicesList = document.getElementById('invoices-list');
    const invoice = document.createElement('div');
    invoice.className = 'invoice-item';
    invoice.innerHTML = `
      <p><strong>Invoice #${invoiceNum}</strong></p>
      <button class="btn btn-sm btn-primary" onclick="CRM.exportInvoicePDF(${invoiceNum})">
        <i class="fas fa-download"></i> PDF
      </button>
    `;
    invoicesList.appendChild(invoice);
    console.log('✅ Invoice created:', invoiceNum);
  },

  addTask() {
    const task = prompt('Enter task description:');
    if (task) {
      const tasksList = document.getElementById('tasks-list');
      const taskItem = document.createElement('div');
      taskItem.className = 'task-item';
      taskItem.innerHTML = `
        <input type="checkbox" onchange="this.parentElement.style.textDecoration = this.checked ? 'line-through' : 'none'">
        <span>${task}</span>
      `;
      tasksList.appendChild(taskItem);
      console.log('✅ Task added:', task);
    }
  },

  addExpense() {
    const amount = prompt('Enter expense amount:');
    if (amount) {
      const expensesList = document.getElementById('expenses-list');
      const expense = document.createElement('div');
      expense.className = 'expense-item';
      expense.innerHTML = `
        <p><strong>$${amount}</strong></p>
        <small>${new Date().toLocaleDateString()}</small>
      `;
      expensesList.appendChild(expense);
      console.log('✅ Expense added: $' + amount);
    }
  },

  addFunds() {
    const amount = prompt('Enter amount to add:');
    if (amount) {
      const transactions = document.getElementById('transactions-list');
      const transaction = document.createElement('div');
      transaction.className = 'transaction-item';
      transaction.innerHTML = `
        <p><strong>+$${amount}</strong></p>
        <small>${new Date().toLocaleDateString()}</small>
      `;
      transactions.appendChild(transaction);
      console.log('✅ Funds added: $' + amount);
    }
  },

  // ====================================
  // Export Functions
  // ====================================

  exportAsPDF() {
    const element = document.querySelector('.crm-grid');
    const opt = {
      margin: 10,
      filename: 'auraSphere-export.pdf',
      image: { type: 'jpeg', quality: 0.98 },
      html2canvas: { scale: 2 },
      jsPDF: { orientation: 'portrait', unit: 'mm', format: 'a4' }
    };

    html2pdf().set(opt).from(element).save();
    console.log('✅ PDF exported');
  },

  exportAsCSV() {
    const data = [
      ['Feature', 'Count', 'Date'],
      ['Clients', document.getElementById('clients-list').children.length, new Date().toLocaleDateString()],
      ['Invoices', document.getElementById('invoices-list').children.length, new Date().toLocaleDateString()],
      ['Tasks', document.getElementById('tasks-list').children.length, new Date().toLocaleDateString()],
      ['Expenses', document.getElementById('expenses-list').children.length, new Date().toLocaleDateString()]
    ];

    let csv = data.map(row => row.join(',')).join('\n');
    const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' });
    const link = document.createElement('a');
    link.setAttribute('href', URL.createObjectURL(blob));
    link.setAttribute('download', `auraSphere-export-${new Date().getTime()}.csv`);
    link.click();
    console.log('✅ CSV exported');
  },

  exportInvoicePDF(invoiceNum) {
    const content = `
      <h2>Invoice #${invoiceNum}</h2>
      <p>Date: ${new Date().toLocaleDateString()}</p>
      <p>Status: Pending</p>
    `;

    const opt = {
      margin: 10,
      filename: `invoice-${invoiceNum}.pdf`,
      image: { type: 'jpeg', quality: 0.98 },
      html2canvas: { scale: 2 },
      jsPDF: { orientation: 'portrait', unit: 'mm', format: 'a4' }
    };

    html2pdf().set(opt).from(content).save();
  },

  // ====================================
  // Theme & Settings
  // ====================================

  toggleDarkMode() {
    document.body.classList.toggle('dark-mode');
    const isDark = document.body.classList.contains('dark-mode');
    localStorage.setItem('aurora_dark_mode', isDark);
    console.log('✅ Dark mode:', isDark);
  },

  loadDarkModePreference() {
    const isDark = localStorage.getItem('aurora_dark_mode') === 'true';
    if (isDark) {
      document.body.classList.add('dark-mode');
    }
  },

  backupData() {
    const backup = {
      timestamp: new Date().toISOString(),
      clients: document.getElementById('clients-list').innerHTML,
      invoices: document.getElementById('invoices-list').innerHTML,
      tasks: document.getElementById('tasks-list').innerHTML,
      expenses: document.getElementById('expenses-list').innerHTML,
      transactions: document.getElementById('transactions-list').innerHTML
    };

    localStorage.setItem('aurora_backup', JSON.stringify(backup));
    alert('✅ Backup created: ' + backup.timestamp);
    console.log('✅ Backup saved');
  },

  // ====================================
  // Language Support
  // ====================================

  initializeLanguageUI() {
    const switcherContainer = document.getElementById('language-switcher-container');
    if (switcherContainer && typeof initializeLanguageSwitcher === 'function') {
      initializeLanguageSwitcher(switcherContainer);
    }
  }
};

// ====================================
// Initialize on Load
// ====================================

document.addEventListener('DOMContentLoaded', () => {
  CRM.init();
});
