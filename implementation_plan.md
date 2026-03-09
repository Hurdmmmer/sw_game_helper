# Implementation Plan: Activate HomePage & Apply Dark Theme

## User Review Required
>
> [!IMPORTANT]
> We are switching from the "Practice Page" to the "Real App Home Page".

## Proposed Changes

### Entry Point

#### [MODIFY] [main.dart](file:///d:/FlutterProject/sw_game_helper/lib/main.dart)

- Import `home_page.dart`
- Change `home` attribute to `const HomePage()`

### UI Design (Windows)

#### [MODIFY] [home_page.dart](file:///d:/FlutterProject/sw_game_helper/lib/platforms/windows/ui/pages/home_page.dart)

- **Theme**: Apply `Slate 900` (#0F172A) background.
- **Layout**: Ensure 3-section layout matches design doc (Game:Control = 3:1).
- **Widgets**: Replace placeholders with colored Containers using the design system palette.

## Verification Plan

### Manual Verification

- Run the app.
- Verify the "Counter" example works (StatefulWidget test).
- Verify the background is dark (Slate 900).
- Verify the layout ratios.
