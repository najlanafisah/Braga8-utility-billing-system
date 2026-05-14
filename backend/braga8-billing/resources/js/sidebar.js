export function initSidebar() {
  const groups = document.querySelectorAll('.menu-group');

  groups.forEach(group => {
    const menu = group.querySelector('.menu-item');
    const submenu = group.querySelector('.submenu');

    if (!menu) return;

    // --- LOGIKA BARU: Cek saat load ---
    // Jika di dalam submenu ada link yang sedang active, 
    // tambahkan class 'active' ke grupnya supaya otomatis terbuka.
    if (submenu && submenu.querySelector('.active')) {
      group.classList.add('active');
    }
    // ----------------------------------

    menu.addEventListener('click', (e) => {
      if (submenu) {
        // Cek apakah klik berasal dari menu utama (bukan link submenu)
        e.preventDefault();

        // Tutup grup lain (Accordion style)
        groups.forEach(g => {
          if (g !== group) g.classList.remove('active');
        });

        // Toggle grup yang diklik
        group.classList.toggle('active');
      }
    });
  });
}