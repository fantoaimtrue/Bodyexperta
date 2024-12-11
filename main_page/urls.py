from django.urls import path
from .views import main_page

app_name = 'main_page'

urlpatterns = [
    path('', main_page, name='main_page'),  # Главная страница

]
