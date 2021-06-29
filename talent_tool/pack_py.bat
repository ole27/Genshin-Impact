pyinstaller -F data.py
rd /s/Q __pycache__
rd /s/Q build
copy .\dist\data.exe .\data.exe
rd /s/Q dist
del data.spec