@echo off
echo Stopping Gradle daemons...
cd android
call .\gradlew.bat --stop
cd ..


echo.
echo Cleaning Flutter build...
call flutter clean

echo.
echo Getting dependencies...
call flutter pub get

echo.
echo Building with verbose output...
cd android
call .\gradlew.bat assembleDebug --stacktrace --info
cd ..

echo.
echo Done! Now try: flutter run
pause
