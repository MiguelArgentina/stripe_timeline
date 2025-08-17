// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"
import "event_modal";

// Open summary card into the "details" Turbo Frame
document.addEventListener("click", (e) => {
    // Find the nearest tx card
    const card = e.target.closest("[data-tx-card]");
    if (!card) return;

    // Ignore clicks on interactive elements inside the card
    if (e.target.closest("a, button, [data-copy], .tx-actions")) return;

    const url = card.getAttribute("data-tx-url");
    if (!url) return;

    e.preventDefault();
    if (window.Turbo?.visit) {
        Turbo.visit(url, { frame: "details" });
    } else {
        // Fallback if Turbo not present (full nav)
        window.location.href = url;
    }
});

