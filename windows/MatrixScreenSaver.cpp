#include <windows.h>
#include <scrnsave.h>
#include <commctrl.h>
#include <vector>
#include <random>
#include <string>

#define TIMER_ID 1
#define CONFIG_DLG 2003
#define IDC_COLOR_COMBO 1001
#define IDC_SPEED_SLIDER 1002

struct MatrixDrop {
    int x;
    float y;
    int length;
    float speed;
    std::vector<wchar_t> characters;
};

class MatrixScreenSaver {
private:
    std::vector<MatrixDrop> drops;
    std::vector<wchar_t> greekChars;
    COLORREF selectedColor;
    int speed;
    std::mt19937 rng;
    
public:
    MatrixScreenSaver() : selectedColor(RGB(0, 255, 0)), speed(50), rng(GetTickCount()) {
        greekChars = {
            L'Α', L'Β', L'Γ', L'Δ', L'Ε', L'Ζ', L'Η', L'Θ', L'Ι', L'Κ', L'Λ', L'Μ',
            L'Ν', L'Ξ', L'Ο', L'Π', L'Ρ', L'Σ', L'Τ', L'Υ', L'Φ', L'Χ', L'Ψ', L'Ω',
            L'α', L'β', L'γ', L'δ', L'ε', L'ζ', L'η', L'θ', L'ι', L'κ', L'λ', L'μ',
            L'ν', L'ξ', L'ο', L'π', L'ρ', L'σ', L'τ', L'υ', L'φ', L'χ', L'ψ', L'ω'
        };
        LoadSettings();
    }
    
    void LoadSettings() {
        HKEY hKey;
        DWORD dwType, dwSize;
        
        if (RegOpenKeyEx(HKEY_CURRENT_USER, L"Software\\MatrixScreenSaver", 0, KEY_READ, &hKey) == ERROR_SUCCESS) {
            dwSize = sizeof(COLORREF);
            RegQueryValueEx(hKey, L"Color", NULL, &dwType, (BYTE*)&selectedColor, &dwSize);
            
            dwSize = sizeof(int);
            RegQueryValueEx(hKey, L"Speed", NULL, &dwType, (BYTE*)&speed, &dwSize);
            
            RegCloseKey(hKey);
        }
    }
    
    void SaveSettings() {
        HKEY hKey;
        DWORD dwDisposition;
        
        if (RegCreateKeyEx(HKEY_CURRENT_USER, L"Software\\MatrixScreenSaver", 0, NULL, 0, KEY_WRITE, NULL, &hKey, &dwDisposition) == ERROR_SUCCESS) {
            RegSetValueEx(hKey, L"Color", 0, REG_DWORD, (BYTE*)&selectedColor, sizeof(COLORREF));
            RegSetValueEx(hKey, L"Speed", 0, REG_DWORD, (BYTE*)&speed, sizeof(int));
            RegCloseKey(hKey);
        }
    }
    
    void InitializeDrops(int width, int height) {
        drops.clear();
        int columns = width / 20;
        
        for (int i = 0; i < columns; i++) {
            MatrixDrop drop;
            drop.x = i * 20;
            drop.y = -static_cast<float>(rng() % 1000);
            drop.length = 5 + rng() % 15;
            drop.speed = 2.0f + (rng() % 30) / 10.0f;
            
            drop.characters.resize(drop.length);
            for (int j = 0; j < drop.length; j++) {
                drop.characters[j] = greekChars[rng() % greekChars.size()];
            }
            
            drops.push_back(drop);
        }
    }
    
    void UpdateDrops(int height) {
        for (auto& drop : drops) {
            drop.y += drop.speed;
            
            if (drop.y > height + drop.length * 20) {
                drop.y = -static_cast<float>(rng() % 1000);
                for (int j = 0; j < drop.length; j++) {
                    drop.characters[j] = greekChars[rng() % greekChars.size()];
                }
            }
            
            if (rng() % 100 < 3) {
                int index = rng() % drop.length;
                drop.characters[index] = greekChars[rng() % greekChars.size()];
            }
        }
    }
    
    void Draw(HDC hdc, int width, int height) {
        RECT rect = {0, 0, width, height};
        FillRect(hdc, &rect, (HBRUSH)GetStockObject(BLACK_BRUSH));
        
        SetTextColor(hdc, selectedColor);
        SetBkMode(hdc, TRANSPARENT);
        
        HFONT hFont = CreateFont(16, 0, 0, 0, FW_NORMAL, FALSE, FALSE, FALSE, DEFAULT_CHARSET, OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS, DEFAULT_QUALITY, FIXED_PITCH | FF_MODERN, L"Consolas");
        HFONT hOldFont = (HFONT)SelectObject(hdc, hFont);
        
        for (const auto& drop : drops) {
            for (int i = 0; i < drop.length; i++) {
                int y = static_cast<int>(drop.y) - i * 16;
                if (y >= -20 && y <= height + 20) {
                    int alpha = (255 * (drop.length - i)) / drop.length;
                    COLORREF color = RGB(
                        (GetRValue(selectedColor) * alpha) / 255,
                        (GetGValue(selectedColor) * alpha) / 255,
                        (GetBValue(selectedColor) * alpha) / 255
                    );
                    SetTextColor(hdc, color);
                    
                    wchar_t ch[2] = {drop.characters[i], L'\0'};
                    TextOut(hdc, drop.x, y, ch, 1);
                }
            }
        }
        
        SelectObject(hdc, hOldFont);
        DeleteObject(hFont);
    }
    
    COLORREF GetSelectedColor() const { return selectedColor; }
    void SetSelectedColor(COLORREF color) { selectedColor = color; }
    int GetSpeed() const { return speed; }
    void SetSpeed(int s) { speed = s; }
};

MatrixScreenSaver* g_pMatrix = nullptr;

LRESULT WINAPI ScreenSaverProc(HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam) {
    static HDC hdc;
    static PAINTSTRUCT ps;
    static RECT rect;
    
    switch (message) {
        case WM_CREATE:
            GetClientRect(hWnd, &rect);
            g_pMatrix = new MatrixScreenSaver();
            g_pMatrix->InitializeDrops(rect.right, rect.bottom);
            SetTimer(hWnd, TIMER_ID, 50, NULL);
            break;
            
        case WM_TIMER:
            if (wParam == TIMER_ID) {
                GetClientRect(hWnd, &rect);
                g_pMatrix->UpdateDrops(rect.bottom);
                InvalidateRect(hWnd, NULL, FALSE);
            }
            break;
            
        case WM_PAINT:
            hdc = BeginPaint(hWnd, &ps);
            GetClientRect(hWnd, &rect);
            g_pMatrix->Draw(hdc, rect.right, rect.bottom);
            EndPaint(hWnd, &ps);
            break;
            
        case WM_DESTROY:
            KillTimer(hWnd, TIMER_ID);
            if (g_pMatrix) {
                delete g_pMatrix;
                g_pMatrix = nullptr;
            }
            break;
            
        default:
            return DefScreenSaverProc(hWnd, message, wParam, lParam);
    }
    return 0;
}

BOOL WINAPI ScreenSaverConfigureDialog(HWND hDlg, UINT message, WPARAM wParam, LPARAM lParam) {
    static MatrixScreenSaver* pConfig = nullptr;
    
    switch (message) {
        case WM_INITDIALOG:
            pConfig = new MatrixScreenSaver();
            
            SendDlgItemMessage(hDlg, IDC_COLOR_COMBO, CB_ADDSTRING, 0, (LPARAM)L"Green");
            SendDlgItemMessage(hDlg, IDC_COLOR_COMBO, CB_ADDSTRING, 0, (LPARAM)L"Blue");
            SendDlgItemMessage(hDlg, IDC_COLOR_COMBO, CB_ADDSTRING, 0, (LPARAM)L"Red");
            SendDlgItemMessage(hDlg, IDC_COLOR_COMBO, CB_ADDSTRING, 0, (LPARAM)L"Yellow");
            SendDlgItemMessage(hDlg, IDC_COLOR_COMBO, CB_ADDSTRING, 0, (LPARAM)L"Cyan");
            SendDlgItemMessage(hDlg, IDC_COLOR_COMBO, CB_ADDSTRING, 0, (LPARAM)L"Purple");
            SendDlgItemMessage(hDlg, IDC_COLOR_COMBO, CB_ADDSTRING, 0, (LPARAM)L"White");
            
            COLORREF color = pConfig->GetSelectedColor();
            int colorIndex = 0;
            if (color == RGB(0, 255, 0)) colorIndex = 0;
            else if (color == RGB(0, 0, 255)) colorIndex = 1;
            else if (color == RGB(255, 0, 0)) colorIndex = 2;
            else if (color == RGB(255, 255, 0)) colorIndex = 3;
            else if (color == RGB(0, 255, 255)) colorIndex = 4;
            else if (color == RGB(255, 0, 255)) colorIndex = 5;
            else if (color == RGB(255, 255, 255)) colorIndex = 6;
            
            SendDlgItemMessage(hDlg, IDC_COLOR_COMBO, CB_SETCURSEL, colorIndex, 0);
            SendDlgItemMessage(hDlg, IDC_SPEED_SLIDER, TBM_SETRANGE, TRUE, MAKELONG(10, 100));
            SendDlgItemMessage(hDlg, IDC_SPEED_SLIDER, TBM_SETPOS, TRUE, pConfig->GetSpeed());
            break;
            
        case WM_COMMAND:
            switch (LOWORD(wParam)) {
                case IDOK:
                    if (pConfig) {
                        int colorIndex = SendDlgItemMessage(hDlg, IDC_COLOR_COMBO, CB_GETCURSEL, 0, 0);
                        COLORREF colors[] = {
                            RGB(0, 255, 0), RGB(0, 0, 255), RGB(255, 0, 0),
                            RGB(255, 255, 0), RGB(0, 255, 255), RGB(255, 0, 255), RGB(255, 255, 255)
                        };
                        pConfig->SetSelectedColor(colors[colorIndex]);
                        
                        int speed = SendDlgItemMessage(hDlg, IDC_SPEED_SLIDER, TBM_GETPOS, 0, 0);
                        pConfig->SetSpeed(speed);
                        
                        pConfig->SaveSettings();
                        delete pConfig;
                        pConfig = nullptr;
                    }
                    EndDialog(hDlg, IDOK);
                    break;
                    
                case IDCANCEL:
                    if (pConfig) {
                        delete pConfig;
                        pConfig = nullptr;
                    }
                    EndDialog(hDlg, IDCANCEL);
                    break;
            }
            break;
    }
    return FALSE;
}

BOOL WINAPI RegisterDialogClasses(HANDLE hInst) {
    return TRUE;
}