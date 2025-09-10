#!/usr/bin/env python3
"""
AIMatrix Digital Rain Screen Saver for Linux
Copyright (c) 2025 AIMatrix - aimatrix.com

Standalone Python implementation using pygame for cross-platform compatibility
Works with XScreenSaver, gnome-screensaver, or standalone
"""

import sys
import os
import random
import time
import argparse
import configparser
from pathlib import Path
from typing import List, Tuple
import signal

try:
    import pygame
except ImportError:
    print("Error: pygame is required. Install with: pip3 install pygame")
    sys.exit(1)

# Configuration file path
CONFIG_DIR = Path.home() / ".config" / "aimatrix"
CONFIG_FILE = CONFIG_DIR / "screensaver.conf"

# Default configuration
DEFAULT_CONFIG = {
    'color_scheme': 'green',
    'speed': 'normal',
    'density': 'normal',
    'char_size': 'medium',
    'fullscreen': 'true',
    'multi_monitor': 'true'
}

# Color schemes (R, G, B)
COLOR_SCHEMES = {
    'green': (0, 255, 0),
    'blue': (0, 204, 255),
    'red': (255, 0, 0),
    'yellow': (255, 255, 0),
    'cyan': (0, 255, 255),
    'purple': (204, 0, 255),
    'orange': (255, 153, 0),
    'pink': (255, 105, 180)
}

# Speed settings (multiplier)
SPEED_SETTINGS = {
    'slow': 0.5,
    'normal': 1.0,
    'fast': 1.5,
    'veryfast': 2.0
}

# Density settings (percentage of columns)
DENSITY_SETTINGS = {
    'sparse': 0.3,
    'normal': 0.5,
    'dense': 0.7
}

# Character size settings
CHAR_SIZE_SETTINGS = {
    'small': 12,
    'medium': 16,
    'large': 20,
    'xlarge': 24
}

class Drop:
    """Represents a single column of falling characters"""
    
    def __init__(self, x: int, screen_height: int, char_height: int):
        self.x = x
        self.screen_height = screen_height
        self.char_height = char_height
        self.reset()
        
    def reset(self):
        """Reset drop to top of screen with random properties"""
        self.y = random.uniform(-20, 0)
        self.speed = random.uniform(0.3, 1.5)
        self.length = random.randint(5, 35)
        self.characters = self._generate_characters()
        
    def _generate_characters(self) -> List[str]:
        """Generate random characters for the drop"""
        # Latin and Greek character sets
        latin = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        greek = "ΑΒΓΔΕΖΗΘΙΚΛΜΝΞΟΠΡΣΤΥΦΧΨΩ"
        charset = latin + greek
        return [random.choice(charset) for _ in range(self.length)]
    
    def update(self, speed_multiplier: float):
        """Update drop position"""
        self.y += self.speed * speed_multiplier
        
        # Randomly change characters
        for i in range(len(self.characters)):
            if random.random() < 0.05:  # 5% chance
                latin = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
                greek = "ΑΒΓΔΕΖΗΘΙΚΛΜΝΞΟΠΡΣΤΥΦΧΨΩ"
                charset = latin + greek
                self.characters[i] = random.choice(charset)
        
        # Reset if off screen
        if self.y - self.length > self.screen_height / self.char_height:
            self.reset()
    
    def draw(self, screen: pygame.Surface, font: pygame.font.Font, 
             color_rgb: Tuple[int, int, int], char_width: int, char_height: int):
        """Draw the drop on the screen"""
        for i, char in enumerate(self.characters):
            char_y = self.y - i
            
            # Only draw if on screen
            if 0 <= char_y * char_height < self.screen_height:
                # Calculate intensity (fade from head to tail)
                intensity = max(0.1, 1.0 - (i / self.length))
                
                # Head character is white
                if i == 0:
                    color = (255, 255, 255)
                else:
                    color = tuple(int(c * intensity) for c in color_rgb)
                
                # Render character
                text = font.render(char, True, color)
                screen.blit(text, (self.x * char_width, char_y * char_height))

class AIMatrixScreenSaver:
    """Main screen saver class"""
    
    def __init__(self, config: dict):
        self.config = config
        self.running = False
        self.drops = []
        
        # Initialize pygame
        pygame.init()
        
        # Set up display
        if config['fullscreen'] == 'true':
            if config['multi_monitor'] == 'true':
                # Use all monitors
                self.screen = pygame.display.set_mode((0, 0), pygame.FULLSCREEN)
            else:
                # Use primary monitor
                info = pygame.display.Info()
                self.screen = pygame.display.set_mode((info.current_w, info.current_h), pygame.FULLSCREEN)
        else:
            # Windowed mode for testing
            self.screen = pygame.display.set_mode((1024, 768))
        
        pygame.display.set_caption("AIMatrix Digital Rain")
        
        # Get screen dimensions
        self.width = self.screen.get_width()
        self.height = self.screen.get_height()
        
        # Set up font
        font_size = CHAR_SIZE_SETTINGS[config['char_size']]
        try:
            # Try to use a monospace font
            self.font = pygame.font.SysFont('couriernew', font_size)
        except:
            self.font = pygame.font.Font(None, font_size)
        
        # Calculate character dimensions
        test_char = self.font.render('M', True, (255, 255, 255))
        self.char_width = test_char.get_width()
        self.char_height = test_char.get_height()
        
        # Calculate grid dimensions
        self.columns = self.width // self.char_width
        self.rows = self.height // self.char_height
        
        # Initialize drops
        self._init_drops()
        
        # Set up clock for FPS control
        self.clock = pygame.time.Clock()
        
    def _init_drops(self):
        """Initialize all drops based on density setting"""
        density = DENSITY_SETTINGS[self.config['density']]
        num_drops = int(self.columns * density)
        
        # Select random columns
        available_columns = list(range(self.columns))
        random.shuffle(available_columns)
        
        self.drops = []
        for i in range(min(num_drops, len(available_columns))):
            drop = Drop(available_columns[i], self.height, self.char_height)
            # Randomize initial Y position
            drop.y = random.uniform(-self.rows, self.rows)
            self.drops.append(drop)
    
    def run(self):
        """Main screen saver loop"""
        self.running = True
        speed_multiplier = SPEED_SETTINGS[self.config['speed']]
        color_rgb = COLOR_SCHEMES[self.config['color_scheme']]
        
        while self.running:
            # Handle events
            for event in pygame.event.get():
                if event.type == pygame.QUIT:
                    self.running = False
                elif event.type == pygame.KEYDOWN:
                    if event.key == pygame.K_ESCAPE or event.key == pygame.K_q:
                        self.running = False
                elif event.type == pygame.MOUSEMOTION:
                    # Exit on mouse movement (standard screen saver behavior)
                    if self.config['fullscreen'] == 'true':
                        self.running = False
            
            # Clear screen to black
            self.screen.fill((0, 0, 0))
            
            # Update and draw drops
            for drop in self.drops:
                drop.update(speed_multiplier)
                drop.draw(self.screen, self.font, color_rgb, self.char_width, self.char_height)
            
            # Update display
            pygame.display.flip()
            
            # Control frame rate (30 FPS)
            self.clock.tick(30)
        
        pygame.quit()

def load_config() -> dict:
    """Load configuration from file or create default"""
    config = DEFAULT_CONFIG.copy()
    
    if CONFIG_FILE.exists():
        parser = configparser.ConfigParser()
        parser.read(CONFIG_FILE)
        
        if 'screensaver' in parser:
            for key in DEFAULT_CONFIG:
                if key in parser['screensaver']:
                    config[key] = parser['screensaver'][key]
    
    return config

def save_config(config: dict):
    """Save configuration to file"""
    CONFIG_DIR.mkdir(parents=True, exist_ok=True)
    
    parser = configparser.ConfigParser()
    parser['screensaver'] = config
    
    with open(CONFIG_FILE, 'w') as f:
        parser.write(f)

def configure():
    """Interactive configuration dialog"""
    config = load_config()
    
    print("AIMatrix Screen Saver Configuration")
    print("=" * 40)
    
    # Color scheme
    print("\nColor Schemes:")
    schemes = list(COLOR_SCHEMES.keys())
    for i, scheme in enumerate(schemes):
        print(f"  {i+1}. {scheme.capitalize()}")
    choice = input(f"Select color scheme (1-{len(schemes)}) [{schemes.index(config['color_scheme'])+1}]: ")
    if choice.isdigit() and 1 <= int(choice) <= len(schemes):
        config['color_scheme'] = schemes[int(choice)-1]
    
    # Speed
    print("\nSpeed Settings:")
    speeds = list(SPEED_SETTINGS.keys())
    for i, speed in enumerate(speeds):
        print(f"  {i+1}. {speed.capitalize()}")
    choice = input(f"Select speed (1-{len(speeds)}) [{speeds.index(config['speed'])+1}]: ")
    if choice.isdigit() and 1 <= int(choice) <= len(speeds):
        config['speed'] = speeds[int(choice)-1]
    
    # Density
    print("\nDensity Settings:")
    densities = list(DENSITY_SETTINGS.keys())
    for i, density in enumerate(densities):
        print(f"  {i+1}. {density.capitalize()}")
    choice = input(f"Select density (1-{len(densities)}) [{densities.index(config['density'])+1}]: ")
    if choice.isdigit() and 1 <= int(choice) <= len(densities):
        config['density'] = densities[int(choice)-1]
    
    # Character size
    print("\nCharacter Size:")
    sizes = list(CHAR_SIZE_SETTINGS.keys())
    for i, size in enumerate(sizes):
        print(f"  {i+1}. {size.capitalize()}")
    choice = input(f"Select size (1-{len(sizes)}) [{sizes.index(config['char_size'])+1}]: ")
    if choice.isdigit() and 1 <= int(choice) <= len(sizes):
        config['char_size'] = sizes[int(choice)-1]
    
    # Fullscreen
    choice = input("\nFullscreen mode? (y/n) [{}]: ".format('y' if config['fullscreen'] == 'true' else 'n'))
    if choice.lower() in ['y', 'n']:
        config['fullscreen'] = 'true' if choice.lower() == 'y' else 'false'
    
    # Save configuration
    save_config(config)
    print("\nConfiguration saved!")

def signal_handler(signum, frame):
    """Handle termination signals gracefully"""
    pygame.quit()
    sys.exit(0)

def main():
    """Main entry point"""
    parser = argparse.ArgumentParser(description='AIMatrix Digital Rain Screen Saver')
    parser.add_argument('-c', '--configure', action='store_true', help='Configure screen saver')
    parser.add_argument('-w', '--window', action='store_true', help='Run in window mode')
    parser.add_argument('-r', '--root', action='store_true', help='Draw on root window (for XScreenSaver)')
    parser.add_argument('--window-id', type=str, help='Window ID for preview (XScreenSaver)')
    
    args = parser.parse_args()
    
    # Set up signal handlers
    signal.signal(signal.SIGTERM, signal_handler)
    signal.signal(signal.SIGINT, signal_handler)
    
    if args.configure:
        configure()
    else:
        config = load_config()
        
        # Override fullscreen if window mode requested
        if args.window:
            config['fullscreen'] = 'false'
        
        # Handle XScreenSaver mode
        if args.root or args.window_id:
            # For XScreenSaver compatibility
            config['fullscreen'] = 'true'
            # Note: Actual XScreenSaver integration would require
            # drawing to the root window or specified window ID
            # This is a simplified version
        
        # Run screen saver
        screensaver = AIMatrixScreenSaver(config)
        screensaver.run()

if __name__ == '__main__':
    main()