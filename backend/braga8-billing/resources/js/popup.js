let selectedDeleteId = null;

export function initPopups() {
  const popups = document.querySelectorAll(".popup");

  document.querySelectorAll("[data-popup]").forEach(trigger => {
      trigger.addEventListener("click", () => {
          const target = trigger.getAttribute("data-popup");
          const popup = document.getElementById(target);

          if (trigger.dataset.id) {
              selectedDeleteId = trigger.dataset.id;
              
              // Tambahin baris ini biar teks unitnya ganti otomatis:
              const unitName = trigger.getAttribute('data-unit');
              const displaySpan = document.getElementById('display-unit-number');
              if (displaySpan && unitName) {
                  displaySpan.innerText = unitName;
              }
          }

          if (popup) popup.classList.add("active");
      });
  });

  popups.forEach(popup => {
    const closeBtn = popup.querySelector(".popup-close");
    const overlay = popup.querySelector(".popup-overlay");

    closeBtn?.addEventListener("click", () => {
      popup.classList.remove("active");
    });

    overlay?.addEventListener("click", () => {
      popup.classList.remove("active");
    });
  });

  document.querySelectorAll("[data-close]").forEach(btn => {
    btn.addEventListener("click", () => {
      const target = btn.getAttribute("data-close");
      const popup = document.getElementById(target);

      if (popup) popup.classList.remove("active");
    });
  });

  const confirmDeleteBtn = document.getElementById("confirm-delete-btn");

  if (confirmDeleteBtn) {
    confirmDeleteBtn.addEventListener("click", () => {
      if (!selectedDeleteId) {
        console.warn("No ID selected for delete");
        return;
      }

      const form = document.getElementById(
        "delete-form-" + selectedDeleteId
      );

      if (form) {
        form.submit();
      } else {
        console.error("Form not found for ID:", selectedDeleteId);
      }
    });
  }
}