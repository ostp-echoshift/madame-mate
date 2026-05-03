// ================================================================
// agenda.js -- Madame-MaTe WhatsApp + Funnel
// OSTP @echoShift  |  Pipeline: Leviatan
// ================================================================
'use strict';

const MMATE_AGENDA = {
  WA: '5213334744397',

  link: function (producto, nombre, nota) {
    const parts = [
      'Hola Madame-MaTe, quiero cotizar un producto.',
      producto ? 'Producto: ' + producto : '',
      nombre   ? 'Nombre: '  + nombre   : '',
      nota     ? 'Nota: '    + nota     : ''
    ].filter(Boolean);
    return 'https://wa.me/' + this.WA + '?text=' + encodeURIComponent(parts.join('\n'));
  },

  initFunnel: function () {
    // Placeholder para funnel de productos
    console.log('Funnel no implementado aún');
  },

  init: function () {
    setTimeout(() => this.initFunnel(), 300);
  }
};

document.addEventListener('DOMContentLoaded', () => MMATE_AGENDA.init());

