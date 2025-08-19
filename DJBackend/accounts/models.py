from django.db import models

# Create your models here.
class User(models.Model):
    phoneNumber= models.CharField(max_length=15, unique=True)
    upiName = models.CharField(max_length=100)
    upiMail=models.EmailField(max_length=254, unique=True)
