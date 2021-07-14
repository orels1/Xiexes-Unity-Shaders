using System.Collections.Generic;
using System.Reflection;
using UnityEditor;
using UnityEngine;

namespace XSToon3 {
  public partial class FoldoutToggles {
    public bool ShowALFallbackFoldout = true;
  }

  public class XSToonALFallbackInspector : XSToonInspector {
    private MaterialProperty _ALFallback = null;
    private MaterialProperty _ALFallbackTexture = null;
    private MaterialProperty _ALFallbackBPM = null;

    public override void PluginGUI(MaterialEditor materialEditor, Material material) {
      DrawALFallbackSettings(materialEditor, material);
    }

    private void DrawALFallbackSettings(MaterialEditor materialEditor, Material material) {
      Foldouts[material].ShowALFallbackFoldout =
        XSStyles.ShurikenFoldout("Audio Link Fallback", Foldouts[material].ShowALFallbackFoldout);
      if (Foldouts[material].ShowALFallbackFoldout) {
        materialEditor.ShaderProperty(_ALFallback,
          new GUIContent("Fallback Mode", "Defines the rim darkening of the iridescence effect"));
        materialEditor.TexturePropertySingleLine(
          new GUIContent("Fallback Texture", "Color Ramp. Defines the colors fo the iridescence effect."),
          _ALFallbackTexture);
        materialEditor.ShaderProperty(_ALFallbackBPM, new GUIContent("Fallback BPM"));
      }
    }
  }
}
