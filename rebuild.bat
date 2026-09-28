@echo off
echo Fixing build issues...
echo.

echo [1/6] Stopping Gradle daemons...
cd android
call .\gradlew.bat --stop
cd ..

echo.
echo [2/6] Cleariradle cacng corrupted Ghe...
rmdir /s /q "%USERPROFILE%\.gradle\caches\8.9\transforms" 2>nul

echo.
echo [3/6] Cleaning Flutter build...
call flutter clean

echo.
echo [4/6] Updating dependencies...
call flutter pub get

echo.
echo [5/6] Cleaning Android build cache...
rmdir /s /q android\app\build 2>nul
rmdir /s /q android\build 2>nul

echo.
echo [6/6] Rebuilding...
call flutter run

pause
