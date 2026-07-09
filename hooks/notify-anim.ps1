# Animated notification overlay: frameless card bottom-right, fades out after
# ~4s. Visual resolution order:
#   1. %LOCALAPPDATA%\claude-done-notify\logo.png   (per-user PNG override, pulses)
#   2. <plugin root>\assets\logo.png                (bundled PNG, pulses)
#   3. <plugin root>\assets\robot_knock_retro.gif   (bundled animated GIF, default)
#   4. none -> spinning 3D cube
# Click focuses the terminal (like the toast it replaces) and dismisses.
# Never steals focus on its own.
param([string]$Message = 'Job done - Claude has finished working.')
$ErrorActionPreference = 'SilentlyContinue'

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

# How long the card stays fully visible before fading out (seconds). Override by
# writing a number to %LOCALAPPDATA%\claude-done-notify\duration (set via
# /notify-duration <sec>). Default 5, clamped to 0.5..60.
$visibleSec = 5
$durFile = Join-Path $env:LOCALAPPDATA 'claude-done-notify\duration'
if (Test-Path $durFile) {
    $raw = (Get-Content $durFile -TotalCount 1 -ErrorAction SilentlyContinue)
    $parsed = 0.0
    if ([double]::TryParse($raw, [System.Globalization.NumberStyles]::Float, [System.Globalization.CultureInfo]::InvariantCulture, [ref]$parsed) `
        -and $parsed -ge 0.5 -and $parsed -le 60) { $visibleSec = $parsed }
}

$logoPath = Join-Path $env:LOCALAPPDATA 'claude-done-notify\logo.png'
if (-not (Test-Path $logoPath)) {
    $logoPath = Join-Path (Split-Path $PSScriptRoot -Parent) 'assets\logo.png'
}
$useLogo = Test-Path $logoPath

$gifPath = Join-Path (Split-Path $PSScriptRoot -Parent) 'assets\robot_knock_retro.gif'
$useGif = (-not $useLogo) -and (Test-Path $gifPath)

if ($useLogo) {
    $visualXaml = @"
      <Grid Width="84" Height="84">
        <Image x:Name="Logo" Width="76" Height="76" Stretch="Uniform"
               RenderTransformOrigin="0.5,0.5" VerticalAlignment="Center" HorizontalAlignment="Center">
          <Image.RenderTransform>
            <TransformGroup>
              <ScaleTransform x:Name="PulseScale" ScaleX="1" ScaleY="1"/>
              <RotateTransform x:Name="Wobble" Angle="0"/>
            </TransformGroup>
          </Image.RenderTransform>
        </Image>
      </Grid>
"@
} elseif ($useGif) {
    $visualXaml = @"
      <Grid Width="84" Height="84">
        <Image x:Name="GifFrame" Width="76" Height="76" Stretch="Uniform"
               VerticalAlignment="Center" HorizontalAlignment="Center"/>
      </Grid>
"@
} else {
    $visualXaml = @"
      <Viewport3D Width="84" Height="84">
        <Viewport3D.Camera>
          <PerspectiveCamera Position="3.2,2.6,3.2" LookDirection="-3.2,-2.6,-3.2" UpDirection="0,1,0" FieldOfView="40"/>
        </Viewport3D.Camera>
        <ModelVisual3D>
          <ModelVisual3D.Content>
            <Model3DGroup>
              <AmbientLight Color="#777777"/>
              <DirectionalLight Color="#FFFFFF" Direction="-1,-1.3,-2"/>
              <Model3DGroup>
                <Model3DGroup.Transform>
                  <Transform3DGroup>
                    <RotateTransform3D>
                      <RotateTransform3D.Rotation>
                        <AxisAngleRotation3D x:Name="SpinX" Axis="1,0,0.35" Angle="0"/>
                      </RotateTransform3D.Rotation>
                    </RotateTransform3D>
                    <RotateTransform3D>
                      <RotateTransform3D.Rotation>
                        <AxisAngleRotation3D x:Name="SpinY" Axis="0,1,0" Angle="0"/>
                      </RotateTransform3D.Rotation>
                    </RotateTransform3D>
                  </Transform3DGroup>
                </Model3DGroup.Transform>
                <GeometryModel3D>
                  <GeometryModel3D.Geometry>
                    <MeshGeometry3D Positions="-0.8,-0.8,0.8 0.8,-0.8,0.8 0.8,0.8,0.8 -0.8,0.8,0.8" TriangleIndices="0 1 2 0 2 3"/>
                  </GeometryModel3D.Geometry>
                  <GeometryModel3D.Material><DiffuseMaterial Brush="#D97757"/></GeometryModel3D.Material>
                </GeometryModel3D>
                <GeometryModel3D>
                  <GeometryModel3D.Geometry>
                    <MeshGeometry3D Positions="0.8,-0.8,-0.8 -0.8,-0.8,-0.8 -0.8,0.8,-0.8 0.8,0.8,-0.8" TriangleIndices="0 1 2 0 2 3"/>
                  </GeometryModel3D.Geometry>
                  <GeometryModel3D.Material><DiffuseMaterial Brush="#A04526"/></GeometryModel3D.Material>
                </GeometryModel3D>
                <GeometryModel3D>
                  <GeometryModel3D.Geometry>
                    <MeshGeometry3D Positions="0.8,-0.8,0.8 0.8,-0.8,-0.8 0.8,0.8,-0.8 0.8,0.8,0.8" TriangleIndices="0 1 2 0 2 3"/>
                  </GeometryModel3D.Geometry>
                  <GeometryModel3D.Material><DiffuseMaterial Brush="#E89070"/></GeometryModel3D.Material>
                </GeometryModel3D>
                <GeometryModel3D>
                  <GeometryModel3D.Geometry>
                    <MeshGeometry3D Positions="-0.8,-0.8,-0.8 -0.8,-0.8,0.8 -0.8,0.8,0.8 -0.8,0.8,-0.8" TriangleIndices="0 1 2 0 2 3"/>
                  </GeometryModel3D.Geometry>
                  <GeometryModel3D.Material><DiffuseMaterial Brush="#B04E2D"/></GeometryModel3D.Material>
                </GeometryModel3D>
                <GeometryModel3D>
                  <GeometryModel3D.Geometry>
                    <MeshGeometry3D Positions="-0.8,0.8,0.8 0.8,0.8,0.8 0.8,0.8,-0.8 -0.8,0.8,-0.8" TriangleIndices="0 1 2 0 2 3"/>
                  </GeometryModel3D.Geometry>
                  <GeometryModel3D.Material><DiffuseMaterial Brush="#F0A585"/></GeometryModel3D.Material>
                </GeometryModel3D>
                <GeometryModel3D>
                  <GeometryModel3D.Geometry>
                    <MeshGeometry3D Positions="-0.8,-0.8,-0.8 0.8,-0.8,-0.8 0.8,-0.8,0.8 -0.8,-0.8,0.8" TriangleIndices="0 1 2 0 2 3"/>
                  </GeometryModel3D.Geometry>
                  <GeometryModel3D.Material><DiffuseMaterial Brush="#8A3B20"/></GeometryModel3D.Material>
                </GeometryModel3D>
              </Model3DGroup>
            </Model3DGroup>
          </ModelVisual3D.Content>
        </ModelVisual3D>
      </Viewport3D>
"@
}

$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Width="360" Height="112" WindowStyle="None" AllowsTransparency="True"
        Background="Transparent" Topmost="True" ShowInTaskbar="False"
        ShowActivated="False" ResizeMode="NoResize" Opacity="0">
  <Border CornerRadius="16" Background="#F21F1E1D" Padding="12">
    <StackPanel Orientation="Horizontal" VerticalAlignment="Center">
$visualXaml
      <StackPanel VerticalAlignment="Center" Margin="14,0,0,0">
        <TextBlock Text="Claude Code" Foreground="#D97757" FontSize="15" FontWeight="Bold" FontFamily="Segoe UI"/>
        <TextBlock x:Name="Msg" Foreground="#F5F5F5" FontSize="12" FontFamily="Segoe UI" TextWrapping="Wrap" MaxWidth="220" Margin="0,3,0,0"/>
      </StackPanel>
    </StackPanel>
  </Border>
</Window>
"@

$window = [Windows.Markup.XamlReader]::Parse($xaml)
if (-not $window) { exit 0 }
$window.FindName('Msg').Text = $Message

# Bottom-right corner, above the taskbar
$wa = [System.Windows.SystemParameters]::WorkArea
$window.Left = $wa.Right - $window.Width - 18
$window.Top = $wa.Bottom - $window.Height - 18

$window.Add_MouseDown({
    # Same focus handoff as a toast click: the wscript shim runs focus-terminal.ps1
    # hidden, using the focus-target.txt written by notify-done.ps1.
    $shim = Join-Path $env:LOCALAPPDATA 'claude-done-notify\focus-launch.vbs'
    if (Test-Path $shim) { Start-Process wscript.exe -ArgumentList "`"$shim`"", 'claude-notify:focus' }
    $window.Close()
})

if ($useLogo) {
    $bmp = New-Object System.Windows.Media.Imaging.BitmapImage
    $bmp.BeginInit()
    $bmp.UriSource = [Uri]$logoPath
    $bmp.CacheOption = [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad
    # Decode at display size so an oversized source PNG costs no extra memory
    $bmp.DecodePixelWidth = 152
    $bmp.EndInit()
    $window.FindName('Logo').Source = $bmp
    $pulse = $window.FindName('PulseScale')
    $wobble = $window.FindName('Wobble')

    $window.Add_Loaded({
        $beat = New-Object System.Windows.Media.Animation.DoubleAnimation(1.0, 1.08, [TimeSpan]::FromMilliseconds(900))
        $beat.AutoReverse = $true
        $beat.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever
        $beat.EasingFunction = New-Object System.Windows.Media.Animation.SineEase
        $pulse.BeginAnimation([System.Windows.Media.ScaleTransform]::ScaleXProperty, $beat)
        $pulse.BeginAnimation([System.Windows.Media.ScaleTransform]::ScaleYProperty, $beat)

        $sway = New-Object System.Windows.Media.Animation.DoubleAnimation(-3, 3, [TimeSpan]::FromMilliseconds(1800))
        $sway.AutoReverse = $true
        $sway.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever
        $sway.EasingFunction = New-Object System.Windows.Media.Animation.SineEase
        $wobble.BeginAnimation([System.Windows.Media.RotateTransform]::AngleProperty, $sway)

        $fadeIn = New-Object System.Windows.Media.Animation.DoubleAnimation(0, 1, [TimeSpan]::FromMilliseconds(250))
        $window.BeginAnimation([System.Windows.Window]::OpacityProperty, $fadeIn)
    })
} elseif ($useGif) {
    # Decode every GIF frame up front, then flip the Image source on a timer that
    # honours each frame's own delay metadata (falling back to ~100ms).
    $decoder = New-Object System.Windows.Media.Imaging.GifBitmapDecoder(
        [Uri]$gifPath,
        [System.Windows.Media.Imaging.BitmapCreateOptions]::None,
        [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad)
    $frames = @($decoder.Frames)
    $delays = foreach ($f in $frames) {
        $cs = $f.Metadata.GetQuery('/grctlext/Delay')
        if ($cs -and $cs -gt 0) { [int]$cs * 10 } else { 100 }
    }
    $delays = @($delays)
    $img = $window.FindName('GifFrame')
    $script:gifIndex = 0
    $img.Source = $frames[0]

    $gifTimer = New-Object System.Windows.Threading.DispatcherTimer
    $gifTimer.Interval = [TimeSpan]::FromMilliseconds($delays[0])
    $gifTimer.Add_Tick({
        $script:gifIndex = ($script:gifIndex + 1) % $frames.Count
        $img.Source = $frames[$script:gifIndex]
        $gifTimer.Interval = [TimeSpan]::FromMilliseconds($delays[$script:gifIndex])
    }.GetNewClosure())

    $window.Add_Loaded({
        $gifTimer.Start()
        $fadeIn = New-Object System.Windows.Media.Animation.DoubleAnimation(0, 1, [TimeSpan]::FromMilliseconds(250))
        $window.BeginAnimation([System.Windows.Window]::OpacityProperty, $fadeIn)
    }.GetNewClosure())
} else {
    $spinY = $window.FindName('SpinY')
    $spinX = $window.FindName('SpinX')

    $window.Add_Loaded({
        $spin1 = New-Object System.Windows.Media.Animation.DoubleAnimation(0, 360, [TimeSpan]::FromSeconds(2.6))
        $spin1.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever
        $spinY.BeginAnimation([System.Windows.Media.Media3D.AxisAngleRotation3D]::AngleProperty, $spin1)

        $spin2 = New-Object System.Windows.Media.Animation.DoubleAnimation(0, 360, [TimeSpan]::FromSeconds(4.1))
        $spin2.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever
        $spinX.BeginAnimation([System.Windows.Media.Media3D.AxisAngleRotation3D]::AngleProperty, $spin2)

        $fadeIn = New-Object System.Windows.Media.Animation.DoubleAnimation(0, 1, [TimeSpan]::FromMilliseconds(250))
        $window.BeginAnimation([System.Windows.Window]::OpacityProperty, $fadeIn)
    })
}

# Fade out and close after the configured visible time (+ ~0.45s fade)
$timer = New-Object System.Windows.Threading.DispatcherTimer
$timer.Interval = [TimeSpan]::FromSeconds($visibleSec)
$timer.Add_Tick({
    $timer.Stop()
    $fade = New-Object System.Windows.Media.Animation.DoubleAnimation(1, 0, [TimeSpan]::FromMilliseconds(450))
    $fade.Add_Completed({ $window.Close() })
    $window.BeginAnimation([System.Windows.Window]::OpacityProperty, $fade)
})
$timer.Start()

$window.ShowDialog() | Out-Null
