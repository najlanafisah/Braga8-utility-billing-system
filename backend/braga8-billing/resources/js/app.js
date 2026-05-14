import './bootstrap';
import Alpine from 'alpinejs';

window.Alpine = Alpine;
Alpine.start();

import { initSidebar } from "./sidebar.js";
import { initPopups } from "./popup.js";
import { initChart } from "./chart.js";
import { initDropdown } from "./dropdown.js";
import { initPayment } from "./payment.js";
import { initUtilityFeatures } from './utility.js';
import { initPasswordToggle } from './popup';

document.addEventListener("DOMContentLoaded", () => {
    initSidebar();
    initPopups();
    initChart();
    initDropdown();
    initPayment();
    initUtilityFeatures();
    initPasswordToggle();

    const openEdit = document.getElementById("openEdit");
    if (openEdit) {
        openEdit.addEventListener("click", () => {
            document.getElementById("detail-profile-popup")?.classList.remove("active");
            document.getElementById("edit-profile-popup")?.classList.add("active");
        });
    }

    document.querySelectorAll('.delete-notif-form').forEach(form => {
        form.addEventListener('submit', function(e) {
            e.preventDefault(); 

            const url = this.action;
            const formData = new FormData(this);
            const notificationItem = this.closest('.notification');

            notificationItem.style.transition = 'all 0.3s ease';
            notificationItem.style.opacity = '0';
            notificationItem.style.transform = 'translateX(20px)';

            fetch(url, {
                method: 'POST',
                body: formData,
                headers: {
                    'X-Requested-With': 'XMLHttpRequest',
                    'X-CSRF-TOKEN': document.querySelector('meta[name="csrf-token"]')?.getAttribute('content')
                }
            })
            .then(response => {
                if (response.ok) {
                    setTimeout(() => {
                        notificationItem.remove();
                        const wrapper = document.querySelector('.notification-wrapper');
                        if (wrapper && wrapper.children.length === 0) {
                            wrapper.innerHTML = '<div class="py-10 text-center text-zinc-400 text-sm italic">Belum ada pemberitahuan</div>';
                        }
                    }, 300);
                } else {
                    notificationItem.style.opacity = '1';
                    notificationItem.style.transform = 'translateX(0)';
                    console.error('Gagal menghapus notifikasi');
                }
            })
            .catch(error => {
                notificationItem.style.opacity = '1';
                notificationItem.style.transform = 'translateX(0)';
                console.error('Error:', error);
            });
        });
    });

    document.querySelectorAll('.read-notif-form').forEach(form => {
        form.addEventListener('submit', function(e) {
            e.preventDefault();

            const url = this.action;
            const formData = new FormData(this);
            const notificationItem = this.closest('.notification');
            const readButtonForm = this;

            fetch(url, {
                method: 'POST',
                body: formData,
                headers: {
                    'X-Requested-With': 'XMLHttpRequest',
                    'X-CSRF-TOKEN': document.querySelector('meta[name="csrf-token"]')?.getAttribute('content')
                }
            })
            .then(response => {
                if (response.ok) {
                    notificationItem.classList.remove('is-unread');
                    notificationItem.classList.add('is-read');
                    
                    const icon = notificationItem.querySelector('.fa-envelope');
                    if(icon) {
                        icon.classList.remove('fa-envelope', 'text-[#FA8327]');
                        icon.classList.add('fa-envelope-open', 'text-zinc-500');
                    }

                    readButtonForm.remove(); // Hapus tombol centang
                }
            })
            .catch(error => console.error('Error:', error));
        });
    });
});