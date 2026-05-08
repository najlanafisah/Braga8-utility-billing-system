export function initSidebar() {
  const groups = document.querySelectorAll('.menu-group');

  groups.forEach(group => {
    const menu = group.querySelector('.menu-item');
    const submenu = group.querySelector('.submenu');

    if (!menu) return;

    menu.addEventListener('click', (e) => {

      if (submenu) {
        e.preventDefault();

        groups.forEach(g => {
          if (g !== group) g.classList.remove('active');
        });

        group.classList.toggle('active');
      }
    });
  });
}