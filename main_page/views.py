from django.shortcuts import render
from .models import Gallery, Services

# Create your views here.

# Домашняя страница
def main_page(request):
    images = Gallery.objects.all()
    services = Services.objects.all()
    context = {
        "images": images,
        "services": services
    }
    return render(request, "main_page/main_page.html", context)