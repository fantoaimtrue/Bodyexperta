from django.shortcuts import render

# Create your views here.

# Домашняя страница
def main_page(request):
    context = {
        "Content": 'content'
    }
    return render(request, "main_page/main_page.html", context)