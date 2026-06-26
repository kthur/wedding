import os
import re

def test_project_structure():
    # Get project root path
    project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
    
    # Assert pubspec.yaml exists
    pubspec_path = os.path.join(project_root, "pubspec.yaml")
    assert os.path.exists(pubspec_path), "pubspec.yaml is missing in project root"
    
    # Assert platform directories exist
    platforms = ["android", "ios", "windows"]
    for platform in platforms:
        platform_path = os.path.join(project_root, platform)
        assert os.path.exists(platform_path), f"Platform directory '{platform}' is missing"
        assert os.path.isdir(platform_path), f"'{platform}' is not a directory"

def test_pubspec_assets_exist():
    # Get project root path
    project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
    pubspec_path = os.path.join(project_root, "pubspec.yaml")
    
    # Read pubspec.yaml content
    with open(pubspec_path, "r", encoding="utf-8") as f:
        content = f.read()
    
    # Simple line-by-line parser to extract assets and fonts
    lines = content.splitlines()
    in_flutter = False
    in_assets = False
    in_fonts = False
    
    assets_to_check = []
    fonts_to_check = []
    
    for line in lines:
        stripped = line.strip()
        if not stripped or stripped.startswith("#"):
            continue
        
        # Check section headers
        if stripped == "flutter:":
            in_flutter = True
            in_assets = False
            in_fonts = False
            continue
        elif in_flutter and stripped == "assets:":
            in_assets = True
            in_fonts = False
            continue
        elif in_flutter and stripped == "fonts:":
            in_fonts = True
            in_assets = False
            continue
        elif stripped.endswith(":") and not stripped.startswith("-"):
            # Other main sections or sub-sections
            if not (stripped.startswith("weight:") or stripped.startswith("asset:") or stripped.startswith("family:")):
                in_assets = False
                in_fonts = False
                if not line.startswith("  "):
                    in_flutter = False
        
        # Parse assets
        if in_flutter and in_assets:
            # Match "- assets/..."
            match = re.match(r"^-\s+(.+)$", stripped)
            if match:
                assets_to_check.append(match.group(1).strip())
                
        # Parse fonts
        if in_flutter and in_fonts:
            # Match "asset: assets/fonts/..."
            if stripped.startswith("- asset:") or stripped.startswith("asset:"):
                match = re.match(r"^(?:-\s+)?asset:\s+(.+)$", stripped)
                if match:
                    fonts_to_check.append(match.group(1).strip())
                    
    # Validate assets exist
    for asset in assets_to_check:
        asset_path = os.path.join(project_root, *asset.split("/"))
        assert os.path.exists(asset_path), f"Declared asset '{asset}' does not exist on disk at '{asset_path}'"

    # Validate fonts exist
    for font in fonts_to_check:
        font_path = os.path.join(project_root, *font.split("/"))
        assert os.path.exists(font_path), f"Declared font asset '{font}' does not exist on disk at '{font_path}'"
