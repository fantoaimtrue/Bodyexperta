from django.db import models



class Gallery(models.Model):
    title = models.TextField(verbose_name='Заголовок')
    image = models.ImageField(verbose_name='Изображение')
    description = models.TextField(verbose_name='Описание')


    def __str__(self):
        return self.title

    class Meta:
        db_table = 'Галерея'



class Services(models.Model):
    title = models.TextField(verbose_name='Заголовок')
    image = models.ImageField(verbose_name='Изображение')
    description = models.TextField(verbose_name='Описание')


    def __str__(self):
        return self.title

    class Meta:
        db_table = 'Сервис'

    

    