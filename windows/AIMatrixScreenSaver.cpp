// AIMatrix Digital Rain Screen Saver for Windows
// Copyright (c) 2025 AIMatrix - aimatrix.com

#include <windows.h>
#include <scrnsave.h>
#include <commctrl.h>
#include <vector>
#include <random>
#include <string>
#include <cmath>
#include <gdiplus.h>

#pragma comment(lib, "scrnsavw.lib")
#pragma comment(lib, "comctl32.lib")
#pragma comment(lib, "gdiplus.lib")

using namespace Gdiplus;

// Configuration keys for registry
#define REGKEY_SCREENSAVER "Software\\AIMatrix\\ScreenSaver"
#define REGVAL_COLORSCHEME "ColorScheme"
#define REGVAL_SPEED "Speed"
#define REGVAL_DENSITY "Density"
#define REGVAL_CHARSIZE "CharacterSize"

// Timer ID for animation
#define TIMER_ANIMATION 1
#define FRAME_RATE 30  // 30 FPS

// Drop structure
struct Drop {
    int x;              // Column position in character units
    float y;            // Current Y position
    float speed;        // Fall speed
    int length;         // Trail length
    std::vector<wchar_t> characters;  // Characters in the drop
    
    Drop() : x(0), y(0), speed(0.5f), length(20) {
        characters.resize(length);
    }
};

// Global variables
static std::vector<Drop> g_drops;
static int g_screenWidth = 0;
static int g_screenHeight = 0;
static int g_charWidth = 16;
static int g_charHeight = 20;
static int g_columns = 0;
static int g_rows = 0;
static std::mt19937 g_rng(GetTickCount());
static ULONG_PTR g_gdiplusToken;
static Graphics* g_graphics = nullptr;
static Bitmap* g_backBuffer = nullptr;
static Graphics* g_backGraphics = nullptr;

// Character sets
static const std::wstring g_latinChars = L"ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
static const std::wstring g_greekChars = L"ΑΒΓΔΕΖΗΘΙΚΛΜΝΞΟΠΡΣΤΥΦΧΨΩ";
static std::wstring g_allChars;

// Configuration
enum ColorScheme {
    COLOR_GREEN = 0,
    COLOR_BLUE,
    COLOR_RED,
    COLOR_YELLOW,
    COLOR_CYAN,
    COLOR_PURPLE,
    COLOR_ORANGE,
    COLOR_PINK
};

enum SpeedSetting {
    SPEED_SLOW = 0,
    SPEED_NORMAL,
    SPEED_FAST,
    SPEED_VERYFAST
};

enum DensitySetting {
    DENSITY_SPARSE = 0,
    DENSITY_NORMAL,
    DENSITY_DENSE
};

enum CharSizeSetting {
    SIZE_SMALL = 0,
    SIZE_MEDIUM,
    SIZE_LARGE,
    SIZE_XLARGE
};

static ColorScheme g_colorScheme = COLOR_GREEN;
static SpeedSetting g_speedSetting = SPEED_NORMAL;
static DensitySetting g_densitySetting = DENSITY_NORMAL;
static CharSizeSetting g_charSize = SIZE_MEDIUM;

// Color functions
Color GetColorForScheme(ColorScheme scheme, float intensity) {
    int alpha = (int)(255 * intensity);
    switch (scheme) {
        case COLOR_GREEN:
            return Color(alpha, 0, 255, 0);
        case COLOR_BLUE:
            return Color(alpha, 0, 204, 255);
        case COLOR_RED:
            return Color(alpha, 255, 0, 0);
        case COLOR_YELLOW:
            return Color(alpha, 255, 255, 0);
        case COLOR_CYAN:
            return Color(alpha, 0, 255, 255);
        case COLOR_PURPLE:
            return Color(alpha, 204, 0, 255);
        case COLOR_ORANGE:
            return Color(alpha, 255, 153, 0);
        case COLOR_PINK:
            return Color(alpha, 255, 105, 180);
        default:
            return Color(alpha, 0, 255, 0);
    }
}

// Get random character
wchar_t GetRandomChar() {
    std::uniform_int_distribution<int> dist(0, g_allChars.length() - 1);
    return g_allChars[dist(g_rng)];
}

// Initialize a drop
void InitializeDrop(Drop& drop, int column, bool randomY = false) {
    drop.x = column;
    
    std::uniform_real_distribution<float> speedDist(0.3f, 1.5f);
    std::uniform_int_distribution<int> lengthDist(5, 35);
    
    // Adjust speed based on setting
    float speedMultiplier = 1.0f;
    switch (g_speedSetting) {
        case SPEED_SLOW: speedMultiplier = 0.5f; break;
        case SPEED_NORMAL: speedMultiplier = 1.0f; break;
        case SPEED_FAST: speedMultiplier = 1.5f; break;
        case SPEED_VERYFAST: speedMultiplier = 2.0f; break;
    }
    
    drop.speed = speedDist(g_rng) * speedMultiplier;
    drop.length = lengthDist(g_rng);
    drop.characters.resize(drop.length);
    
    if (randomY) {
        std::uniform_real_distribution<float> yDist(-g_rows, g_rows);
        drop.y = yDist(g_rng);
    } else {
        drop.y = -drop.length;
    }
    
    // Fill with random characters
    for (int i = 0; i < drop.length; i++) {
        drop.characters[i] = GetRandomChar();
    }
}

// Initialize all drops
void InitializeDrops() {
    g_columns = g_screenWidth / g_charWidth;
    g_rows = g_screenHeight / g_charHeight;
    
    // Determine number of drops based on density
    float densityFactor = 0.5f;
    switch (g_densitySetting) {
        case DENSITY_SPARSE: densityFactor = 0.3f; break;
        case DENSITY_NORMAL: densityFactor = 0.5f; break;
        case DENSITY_DENSE: densityFactor = 0.7f; break;
    }
    
    int numDrops = (int)(g_columns * densityFactor);
    g_drops.resize(numDrops);
    
    // Initialize each drop at a random column
    std::vector<int> availableColumns;
    for (int i = 0; i < g_columns; i++) {
        availableColumns.push_back(i);
    }
    
    std::shuffle(availableColumns.begin(), availableColumns.end(), g_rng);
    
    for (int i = 0; i < numDrops && i < availableColumns.size(); i++) {
        InitializeDrop(g_drops[i], availableColumns[i], true);
    }
}

// Update drop positions and characters
void UpdateDrops() {
    std::uniform_real_distribution<float> changeDist(0.0f, 1.0f);
    
    for (auto& drop : g_drops) {
        // Move drop down
        drop.y += drop.speed;
        
        // Randomly change some characters
        for (int i = 0; i < drop.length; i++) {
            if (changeDist(g_rng) < 0.1f) {  // 10% chance to change
                drop.characters[i] = GetRandomChar();
            }
        }
        
        // Reset drop if it's completely off screen
        if (drop.y - drop.length > g_rows) {
            InitializeDrop(drop, drop.x, false);
        }
    }
}

// Render all drops
void RenderDrops(Graphics* graphics) {
    // Clear to black
    graphics->Clear(Color(255, 0, 0, 0));
    
    // Set up font
    FontFamily fontFamily(L"Courier New");
    
    float fontSize = 14.0f;
    switch (g_charSize) {
        case SIZE_SMALL: fontSize = 10.0f; break;
        case SIZE_MEDIUM: fontSize = 14.0f; break;
        case SIZE_LARGE: fontSize = 18.0f; break;
        case SIZE_XLARGE: fontSize = 22.0f; break;
    }
    
    Font font(&fontFamily, fontSize, FontStyleRegular, UnitPixel);
    
    // Update character dimensions based on font
    RectF charBounds;
    graphics->MeasureString(L"M", 1, &font, PointF(0, 0), &charBounds);
    g_charWidth = (int)charBounds.Width;
    g_charHeight = (int)charBounds.Height;
    
    // Draw each drop
    for (const auto& drop : g_drops) {
        for (int i = 0; i < drop.length; i++) {
            float charY = drop.y - i;
            
            // Only draw if on screen
            if (charY >= 0 && charY < g_rows) {
                // Calculate intensity (fade from head to tail)
                float intensity = 1.0f - (float)i / drop.length;
                intensity = max(0.1f, intensity);  // Minimum 10% opacity
                
                // Get color based on intensity
                Color color = GetColorForScheme(g_colorScheme, intensity);
                
                // Make the head character white for emphasis
                if (i == 0) {
                    color = Color(255, 255, 255, 255);
                }
                
                SolidBrush brush(color);
                
                // Draw character
                wchar_t str[2] = { drop.characters[i], 0 };
                PointF point((float)(drop.x * g_charWidth), (float)(charY * g_charHeight));
                graphics->DrawString(str, 1, &font, point, &brush);
            }
        }
    }
}

// Load settings from registry
void LoadSettings() {
    HKEY hKey;
    if (RegOpenKeyEx(HKEY_CURRENT_USER, REGKEY_SCREENSAVER, 0, KEY_READ, &hKey) == ERROR_SUCCESS) {
        DWORD value;
        DWORD size = sizeof(DWORD);
        
        if (RegQueryValueEx(hKey, REGVAL_COLORSCHEME, NULL, NULL, (LPBYTE)&value, &size) == ERROR_SUCCESS) {
            g_colorScheme = (ColorScheme)value;
        }
        
        if (RegQueryValueEx(hKey, REGVAL_SPEED, NULL, NULL, (LPBYTE)&value, &size) == ERROR_SUCCESS) {
            g_speedSetting = (SpeedSetting)value;
        }
        
        if (RegQueryValueEx(hKey, REGVAL_DENSITY, NULL, NULL, (LPBYTE)&value, &size) == ERROR_SUCCESS) {
            g_densitySetting = (DensitySetting)value;
        }
        
        if (RegQueryValueEx(hKey, REGVAL_CHARSIZE, NULL, NULL, (LPBYTE)&value, &size) == ERROR_SUCCESS) {
            g_charSize = (CharSizeSetting)value;
        }
        
        RegCloseKey(hKey);
    }
}

// Save settings to registry
void SaveSettings() {
    HKEY hKey;
    if (RegCreateKeyEx(HKEY_CURRENT_USER, REGKEY_SCREENSAVER, 0, NULL, 0, KEY_WRITE, NULL, &hKey, NULL) == ERROR_SUCCESS) {
        DWORD value;
        
        value = g_colorScheme;
        RegSetValueEx(hKey, REGVAL_COLORSCHEME, 0, REG_DWORD, (LPBYTE)&value, sizeof(DWORD));
        
        value = g_speedSetting;
        RegSetValueEx(hKey, REGVAL_SPEED, 0, REG_DWORD, (LPBYTE)&value, sizeof(DWORD));
        
        value = g_densitySetting;
        RegSetValueEx(hKey, REGVAL_DENSITY, 0, REG_DWORD, (LPBYTE)&value, sizeof(DWORD));
        
        value = g_charSize;
        RegSetValueEx(hKey, REGVAL_CHARSIZE, 0, REG_DWORD, (LPBYTE)&value, sizeof(DWORD));
        
        RegCloseKey(hKey);
    }
}

// Screen saver procedure
LRESULT WINAPI ScreenSaverProc(HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam) {
    switch (message) {
        case WM_CREATE: {
            // Initialize GDI+
            GdiplusStartupInput gdiplusStartupInput;
            GdiplusStartup(&g_gdiplusToken, &gdiplusStartupInput, NULL);
            
            // Get screen dimensions
            RECT rect;
            GetClientRect(hWnd, &rect);
            g_screenWidth = rect.right - rect.left;
            g_screenHeight = rect.bottom - rect.top;
            
            // Create back buffer
            g_backBuffer = new Bitmap(g_screenWidth, g_screenHeight);
            g_backGraphics = new Graphics(g_backBuffer);
            g_backGraphics->SetTextRenderingHint(TextRenderingHintAntiAlias);
            
            // Initialize character set
            g_allChars = g_latinChars + g_greekChars;
            
            // Load settings
            LoadSettings();
            
            // Initialize drops
            InitializeDrops();
            
            // Start animation timer
            SetTimer(hWnd, TIMER_ANIMATION, 1000 / FRAME_RATE, NULL);
            
            return 0;
        }
        
        case WM_TIMER: {
            if (wParam == TIMER_ANIMATION) {
                // Update animation
                UpdateDrops();
                
                // Trigger repaint
                InvalidateRect(hWnd, NULL, FALSE);
            }
            return 0;
        }
        
        case WM_PAINT: {
            PAINTSTRUCT ps;
            HDC hdc = BeginPaint(hWnd, &ps);
            
            // Render to back buffer
            RenderDrops(g_backGraphics);
            
            // Copy back buffer to screen
            Graphics graphics(hdc);
            graphics.DrawImage(g_backBuffer, 0, 0);
            
            EndPaint(hWnd, &ps);
            return 0;
        }
        
        case WM_DESTROY: {
            // Clean up
            KillTimer(hWnd, TIMER_ANIMATION);
            
            delete g_backGraphics;
            delete g_backBuffer;
            
            // Shutdown GDI+
            GdiplusShutdown(g_gdiplusToken);
            
            PostQuitMessage(0);
            return 0;
        }
    }
    
    return DefScreenSaverProc(hWnd, message, wParam, lParam);
}

// Configuration dialog procedure
BOOL WINAPI ScreenSaverConfigureDialog(HWND hDlg, UINT message, WPARAM wParam, LPARAM lParam) {
    switch (message) {
        case WM_INITDIALOG: {
            // Load current settings
            LoadSettings();
            
            // Initialize controls
            SendDlgItemMessage(hDlg, IDC_COLOR_COMBO, CB_ADDSTRING, 0, (LPARAM)L"Green (Classic)");
            SendDlgItemMessage(hDlg, IDC_COLOR_COMBO, CB_ADDSTRING, 0, (LPARAM)L"Blue");
            SendDlgItemMessage(hDlg, IDC_COLOR_COMBO, CB_ADDSTRING, 0, (LPARAM)L"Red");
            SendDlgItemMessage(hDlg, IDC_COLOR_COMBO, CB_ADDSTRING, 0, (LPARAM)L"Yellow");
            SendDlgItemMessage(hDlg, IDC_COLOR_COMBO, CB_ADDSTRING, 0, (LPARAM)L"Cyan");
            SendDlgItemMessage(hDlg, IDC_COLOR_COMBO, CB_ADDSTRING, 0, (LPARAM)L"Purple");
            SendDlgItemMessage(hDlg, IDC_COLOR_COMBO, CB_ADDSTRING, 0, (LPARAM)L"Orange");
            SendDlgItemMessage(hDlg, IDC_COLOR_COMBO, CB_ADDSTRING, 0, (LPARAM)L"Pink");
            SendDlgItemMessage(hDlg, IDC_COLOR_COMBO, CB_SETCURSEL, g_colorScheme, 0);
            
            SendDlgItemMessage(hDlg, IDC_SPEED_COMBO, CB_ADDSTRING, 0, (LPARAM)L"Slow");
            SendDlgItemMessage(hDlg, IDC_SPEED_COMBO, CB_ADDSTRING, 0, (LPARAM)L"Normal");
            SendDlgItemMessage(hDlg, IDC_SPEED_COMBO, CB_ADDSTRING, 0, (LPARAM)L"Fast");
            SendDlgItemMessage(hDlg, IDC_SPEED_COMBO, CB_ADDSTRING, 0, (LPARAM)L"Very Fast");
            SendDlgItemMessage(hDlg, IDC_SPEED_COMBO, CB_SETCURSEL, g_speedSetting, 0);
            
            SendDlgItemMessage(hDlg, IDC_DENSITY_COMBO, CB_ADDSTRING, 0, (LPARAM)L"Sparse");
            SendDlgItemMessage(hDlg, IDC_DENSITY_COMBO, CB_ADDSTRING, 0, (LPARAM)L"Normal");
            SendDlgItemMessage(hDlg, IDC_DENSITY_COMBO, CB_ADDSTRING, 0, (LPARAM)L"Dense");
            SendDlgItemMessage(hDlg, IDC_DENSITY_COMBO, CB_SETCURSEL, g_densitySetting, 0);
            
            SendDlgItemMessage(hDlg, IDC_SIZE_COMBO, CB_ADDSTRING, 0, (LPARAM)L"Small");
            SendDlgItemMessage(hDlg, IDC_SIZE_COMBO, CB_ADDSTRING, 0, (LPARAM)L"Medium");
            SendDlgItemMessage(hDlg, IDC_SIZE_COMBO, CB_ADDSTRING, 0, (LPARAM)L"Large");
            SendDlgItemMessage(hDlg, IDC_SIZE_COMBO, CB_ADDSTRING, 0, (LPARAM)L"Extra Large");
            SendDlgItemMessage(hDlg, IDC_SIZE_COMBO, CB_SETCURSEL, g_charSize, 0);
            
            return TRUE;
        }
        
        case WM_COMMAND: {
            switch (LOWORD(wParam)) {
                case IDOK: {
                    // Save settings
                    g_colorScheme = (ColorScheme)SendDlgItemMessage(hDlg, IDC_COLOR_COMBO, CB_GETCURSEL, 0, 0);
                    g_speedSetting = (SpeedSetting)SendDlgItemMessage(hDlg, IDC_SPEED_COMBO, CB_GETCURSEL, 0, 0);
                    g_densitySetting = (DensitySetting)SendDlgItemMessage(hDlg, IDC_DENSITY_COMBO, CB_GETCURSEL, 0, 0);
                    g_charSize = (CharSizeSetting)SendDlgItemMessage(hDlg, IDC_SIZE_COMBO, CB_GETCURSEL, 0, 0);
                    
                    SaveSettings();
                    EndDialog(hDlg, IDOK);
                    return TRUE;
                }
                
                case IDCANCEL: {
                    EndDialog(hDlg, IDCANCEL);
                    return TRUE;
                }
            }
            break;
        }
    }
    
    return FALSE;
}

// Register dialog as dialog procedure
BOOL WINAPI RegisterDialogClasses(HANDLE hInst) {
    return TRUE;
}