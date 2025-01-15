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
