/* exported applySmartOverflow */
function applySmartOverflow() {
    $(".smart-overflow").each(function(_, el) {
        var link = document.createElement('a');
        link.href = '#'; link.className = 'ellipsis-link';

        if (el.offsetWidth < el.scrollWidth) {
            link.addEventListener('click', function (e) {
                e.preventDefault();
                el.classList.remove('smart-overflow');
            });
            el.appendChild(link);
        }
    });
}
