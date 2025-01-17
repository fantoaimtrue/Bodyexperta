// Получаем кнопку
const button = document.querySelector(".floating-button");

// Функция для создания волны
function createWave(event) {
  // Создаем новый элемент для волны
  const wave = document.createElement("div");
  wave.classList.add("floating-button-wave");

  // Получаем позицию кнопки
  const buttonRect = button.getBoundingClientRect();
  const buttonCenterX = buttonRect.left + buttonRect.width / 2;
  const buttonCenterY = buttonRect.top + buttonRect.height / 2;

  // Устанавливаем позицию волны в центр кнопки
  wave.style.left = `${event.clientX - buttonCenterX}px`;
  wave.style.top = `${event.clientY - buttonCenterY}px`;

  // Добавляем волну на страницу
  button.appendChild(wave);

  // Убираем волну после окончания анимации
  wave.addEventListener("animationend", () => {
    wave.remove();
  });
}

// Добавляем обработчик клика на кнопку
button.addEventListener("click", createWave);


// Находим изображение
const heroImage = document.querySelector('.hero img')
// Добавляем событие прокрутки
window.addEventListener('scroll', () => {
  // Получаем текущую позицию прокрутки
  const scrollPosition = window.scrollY
  // Вычисляем коэффициент масштабирования (например, от 1 до 1.5)
  const scale = 1 + scrollPosition / 5000
  // Применяем масштаб к изображению
  heroImage.style.transform = `scale(${scale})`;
});


  document.addEventListener("DOMContentLoaded", function () {
    let navLinks = document.querySelectorAll(".nav-link"); // Получаем все ссылки в меню
    let navbarCollapse = document.getElementById("navbarNav"); // Получаем меню

    navLinks.forEach(function (link) {
      link.addEventListener("click", function (event) {
        let targetId = this.getAttribute("href").substring(1); // Получаем ID секции без #
        let targetElement = document.getElementById(targetId); // Находим элемент

        if (targetElement) {
          event.preventDefault(); // Останавливаем стандартный переход

          // Плавный скролл с учетом фиксированного меню (высота ~70px)
          window.scrollTo({
            top: targetElement.offsetTop - 70,
            behavior: "smooth"
          });

          // Закрытие бургер-меню после клика
          if (navbarCollapse.classList.contains("show")) {
            new bootstrap.Collapse(navbarCollapse).hide();
          }
        }
      });
    });
  });

