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
        openEdit?.addEventListener("click", () => {
            document.getElementById("detail-profile-popup")?.classList.remove("active");
            document.getElementById("edit-profile-popup")?.classList.add("active");
        });
    }
});