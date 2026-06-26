import os

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
