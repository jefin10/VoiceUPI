from .views import SignUp, send_otp, verify_otp
from django.urls import path

urlpatterns = [
    path('signup/', SignUp, name='signup'),
    path('send_otp/', send_otp, name='send_otp'),
    path('verify_otp/', verify_otp, name='verify_otp'),
]
