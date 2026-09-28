@echo off
echo Fixing Gradle cache corruption...
echo.

echo [1/6] Stopping all Gradle daemons...
cd android
call .\gradlew.bat --stop
cd ..

echo.
echo [2/6] Deleting corrupted Gradle cache...
rmdir /s /q "%USERPROFILE%\.gradle\caches\8.9\transforms" 2>nul

echo.
echo [3/6] Cleaning Flutter build...
call flutter clean

echo.
echo [4/6] Removing pub cache for mobile_scanner...
rmdir /s /q "%LOCALAPPDATA%\Pub\Cache\hosted\pub.dev\mobile_scanner-5.2.3" 2>nul

echo.
echo [5/6] Getting fresh dependencies...
call flutter pub get

echo.
echo [6/6] Rebuilding project...
call flutter run

pause

