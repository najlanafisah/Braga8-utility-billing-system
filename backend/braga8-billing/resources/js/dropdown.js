export function initDropdown() {
    const dropdowns = document.querySelectorAll(".custom-dropdown");

    dropdowns.forEach(dropdown => {
        const selected = dropdown.querySelector(".dropdown-selected");
        const options = dropdown.querySelectorAll(".option");
        const placeholder = dropdown.querySelector(".placeholder");
        const hiddenInput = dropdown.querySelector('input[type="hidden"]');
        const optionsContainer = dropdown.querySelector(".dropdown-options");

        selected.addEventListener("click", (e) => {
            e.stopPropagation();
            
            // Tutup semua dropdown lain yang sedang terbuka
            document.querySelectorAll(".custom-dropdown").forEach(d => {
                if (d !== dropdown) {
                    d.classList.remove("active");
                    const otherContainer = d.querySelector(".dropdown-options");
                    if (otherContainer) otherContainer.style.overflowY = 'hidden'; // Reset yang lain
                }
            });

            // Toggle dropdown saat ini
            dropdown.classList.toggle("active");

            // LOGIKA IF ELSE: Atur overflow berdasarkan status active
            if (optionsContainer) {
                if (dropdown.classList.contains("active")) {
                    // IF terbukan: tunggu transisi CSS selesai (250ms), baru aktifkan scroll
                    setTimeout(() => {
                        if (dropdown.classList.contains("active")) {
                            optionsContainer.style.overflowY = 'auto';
                        }
                    }, 250);
                } else {
                    // ELSE tertutup: langsung amankan overflow ke hidden
                    optionsContainer.style.overflowY = 'hidden';
                }
            }
        });

        options.forEach(option => {
            option.addEventListener("click", () => {
                placeholder.textContent = option.textContent;
                placeholder.style.color = "#333";

                let val = option.getAttribute('data-value') || option.textContent.trim();
                
                if (hiddenInput) {
                    if (hiddenInput.name === 'status') {
                        val = val.toLowerCase();
                    }
                    hiddenInput.value = val;

                    if (hiddenInput.name === 'tenant_id') {
                        const unitDropdown = document.getElementById('unitDropdown');
                        if (unitDropdown) {
                            const unitOptions = unitDropdown.querySelectorAll('.option');
                            const unitPlaceholder = unitDropdown.querySelector('.placeholder');
                            const unitInput = document.getElementById('unit_id_input');

                            unitInput.value = "";
                            unitPlaceholder.textContent = "-- Pilih Unit --";

                            unitOptions.forEach(opt => {
                                if (opt.getAttribute('data-tenant') === val) {
                                    opt.style.display = 'block';
                                } else {
                                    opt.style.display = 'none';
                                }
                            });
                        }
                    }
                }

                if (option.hasAttribute('data-total')) {
                    const total = option.getAttribute('data-total');
                    const amountInput = document.getElementById('modal_amount_paid');
                    const minLabel = document.getElementById('modal_min_label');
                    
                    if (amountInput) amountInput.value = total;
                    if (minLabel) {
                        minLabel.innerText = 'Tagihan: Rp ' + new Intl.NumberFormat('id-ID').format(total);
                    }
                }

                // Saat opsi dipilih, pastikan dropdown ditutup dan reset overflow ke hidden
                dropdown.classList.remove("active");
                if (optionsContainer) optionsContainer.style.overflowY = 'hidden';
            });
        });
    });

    // Event global ketika user klik di luar area mana pun
    document.addEventListener("click", () => {
        document.querySelectorAll(".custom-dropdown").forEach(d => {
            d.classList.remove("active");
            const container = d.querySelector(".dropdown-options");
            if (container) container.style.overflowY = 'hidden'; // Kelola semua saat di luar klik
        });
    });
}