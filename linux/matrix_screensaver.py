#!/usr/bin/env python3
import pygame
import random
import sys
import json
import os
import argparse
from dataclasses import dataclass
from typing import List, Tuple

@dataclass
class MatrixDrop:
    x: int
    y: float
    length: int
    speed: float
    characters: List[str]

class MatrixScreenSaver:
    def __init__(self, width: int = 1920, height: int = 1080, fullscreen: bool = True):
        pygame.init()
        
        self.width = width
        self.height = height
        self.fullscreen = fullscreen
        
        self.greek_chars = [
            'Α', 'Β', 'Γ', 'Δ', 'Ε', 'Ζ', 'Η', 'Θ', 'Ι', 'Κ', 'Λ', 'Μ',
            'Ν', 'Ξ', 'Ο', 'Π', 'Ρ', 'Σ', 'Τ', 'Υ', 'Φ', 'Χ', 'Ψ', 'Ω',
            'α', 'β', 'γ', 'δ', 'ε', 'ζ', 'η', 'θ', 'ι', 'κ', 'λ', 'μ',
            'ν', 'ξ', 'ο', 'π', 'ρ', 'σ', 'τ', 'υ', 'φ', 'χ', 'ψ', 'ω'
        ]
        
        self.color_map = {
            'green': (0, 255, 0),
            'blue': (0, 100, 255),
            'red': (255, 50, 50),
            'yellow': (255, 255, 0),
            'cyan': (0, 255, 255),
            'purple': (255, 0, 255),
            'white': (255, 255, 255)
        }
        
        self.config = self.load_config()
        self.setup_display()
        self.setup_font()
        self.initialize_drops()
        
    def load_config(self) -> dict:
        config_path = os.path.expanduser('~/.config/matrix_screensaver.json')
        default_config = {
            'color': 'green',
            'speed': 1.0,
            'drop_count': 50,
            'char_size': 16
        }
        
        try:
            if os.path.exists(config_path):
                with open(config_path, 'r') as f:
                    config = json.load(f)
                    return {**default_config, **config}
        except Exception as e:
            print(f"Error loading config: {e}")
        
        return default_config
    
    def save_config(self):
        config_path = os.path.expanduser('~/.config/matrix_screensaver.json')
        os.makedirs(os.path.dirname(config_path), exist_ok=True)
        
        try:
            with open(config_path, 'w') as f:
                json.dump(self.config, f, indent=2)
        except Exception as e:
            print(f"Error saving config: {e}")
    
    def setup_display(self):
        if self.fullscreen:
            self.screen = pygame.display.set_mode((0, 0), pygame.FULLSCREEN)
            self.width, self.height = self.screen.get_size()
        else:
            self.screen = pygame.display.set_mode((self.width, self.height))
        
        pygame.display.set_caption("Matrix Digital Rain")
        pygame.mouse.set_visible(False)
    
    def setup_font(self):
        font_size = self.config.get('char_size', 16)
        try:
            self.font = pygame.font.Font('DejaVuSansMono.ttf', font_size)
        except:
            try:
                self.font = pygame.font.SysFont('monospace', font_size)
            except:
                self.font = pygame.font.Font(None, font_size)
    
    def initialize_drops(self):
        self.drops = []
        columns = self.width // 20
        drop_count = min(columns, self.config.get('drop_count', 50))
        
        for i in range(drop_count):
            x = (i * self.width // drop_count) + random.randint(0, 20)
            drop = MatrixDrop(
                x=x,
                y=random.randint(-1000, 0),
                length=random.randint(5, 20),
                speed=random.uniform(2, 6) * self.config.get('speed', 1.0),
                characters=[random.choice(self.greek_chars) for _ in range(20)]
            )
            self.drops.append(drop)
    
    def update_drops(self):
        for drop in self.drops:
            drop.y += drop.speed
            
            if drop.y > self.height + len(drop.characters) * 20:
                drop.y = random.randint(-1000, -100)
                drop.characters = [random.choice(self.greek_chars) for _ in range(len(drop.characters))]
            
            if random.random() < 0.02:
                idx = random.randint(0, len(drop.characters) - 1)
                drop.characters[idx] = random.choice(self.greek_chars)
    
    def draw_drops(self):
        self.screen.fill((0, 0, 0))
        
        base_color = self.color_map.get(self.config.get('color', 'green'), (0, 255, 0))
        
        for drop in self.drops:
            for i, char in enumerate(drop.characters[:drop.length]):
                y_pos = int(drop.y) - i * 20
                
                if -30 <= y_pos <= self.height + 30:
                    alpha = max(0, min(255, int(255 * (drop.length - i) / drop.length)))
                    color = tuple(int(c * alpha / 255) for c in base_color)
                    
                    try:
                        text_surface = self.font.render(char, True, color)
                        self.screen.blit(text_surface, (drop.x, y_pos))
                    except:
                        pass
    
    def handle_events(self) -> bool:
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                return False
            elif event.type == pygame.KEYDOWN:
                if event.key == pygame.K_ESCAPE or event.key == pygame.K_q:
                    return False
                elif event.key == pygame.K_c:
                    self.show_config_menu()
            elif event.type == pygame.MOUSEBUTTONDOWN:
                return False
        
        return True
    
    def show_config_menu(self):
        menu_active = True
        clock = pygame.time.Clock()
        
        colors = list(self.color_map.keys())
        current_color_idx = colors.index(self.config.get('color', 'green'))
        
        while menu_active:
            for event in pygame.event.get():
                if event.type == pygame.KEYDOWN:
                    if event.key == pygame.K_ESCAPE:
                        menu_active = False
                    elif event.key == pygame.K_LEFT:
                        current_color_idx = (current_color_idx - 1) % len(colors)
                        self.config['color'] = colors[current_color_idx]
                    elif event.key == pygame.K_RIGHT:
                        current_color_idx = (current_color_idx + 1) % len(colors)
                        self.config['color'] = colors[current_color_idx]
                    elif event.key == pygame.K_UP:
                        self.config['speed'] = min(3.0, self.config['speed'] + 0.1)
                    elif event.key == pygame.K_DOWN:
                        self.config['speed'] = max(0.1, self.config['speed'] - 0.1)
                    elif event.key == pygame.K_RETURN:
                        self.save_config()
                        menu_active = False
            
            self.screen.fill((0, 0, 0))
            
            menu_font = pygame.font.Font(None, 36)
            title = menu_font.render("Matrix Configuration", True, (0, 255, 0))
            self.screen.blit(title, (self.width // 2 - title.get_width() // 2, 100))
            
            color_text = f"Color: {colors[current_color_idx]} (← →)"
            color_surface = menu_font.render(color_text, True, self.color_map[colors[current_color_idx]])
            self.screen.blit(color_surface, (self.width // 2 - color_surface.get_width() // 2, 200))
            
            speed_text = f"Speed: {self.config['speed']:.1f} (↑ ↓)"
            speed_surface = menu_font.render(speed_text, True, (255, 255, 255))
            self.screen.blit(speed_surface, (self.width // 2 - speed_surface.get_width() // 2, 250))
            
            help_text = "Press ENTER to save, ESC to cancel"
            help_surface = menu_font.render(help_text, True, (128, 128, 128))
            self.screen.blit(help_surface, (self.width // 2 - help_surface.get_width() // 2, 350))
            
            pygame.display.flip()
            clock.tick(30)
    
    def run(self):
        clock = pygame.time.Clock()
        running = True
        
        print("Matrix Digital Rain Screen Saver")
        print("Controls:")
        print("  ESC or Q - Exit")
        print("  C - Configuration")
        print("  Mouse click - Exit")
        
        while running:
            running = self.handle_events()
            self.update_drops()
            self.draw_drops()
            pygame.display.flip()
            clock.tick(60)
        
        pygame.quit()

def main():
    parser = argparse.ArgumentParser(description='Matrix Digital Rain Screen Saver')
    parser.add_argument('--width', type=int, default=1920, help='Screen width (ignored in fullscreen)')
    parser.add_argument('--height', type=int, default=1080, help='Screen height (ignored in fullscreen)')
    parser.add_argument('--windowed', action='store_true', help='Run in windowed mode')
    parser.add_argument('--config', action='store_true', help='Show configuration and exit')
    
    args = parser.parse_args()
    
    if args.config:
        screensaver = MatrixScreenSaver(args.width, args.height, not args.windowed)
        screensaver.show_config_menu()
        pygame.quit()
        return
    
    screensaver = MatrixScreenSaver(args.width, args.height, not args.windowed)
    screensaver.run()

if __name__ == '__main__':
    main()