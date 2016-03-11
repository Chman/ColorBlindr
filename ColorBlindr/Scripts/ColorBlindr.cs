using UnityEngine;

[ExecuteInEditMode, AddComponentMenu("Image Effects/ColorBlindr")]
[RequireComponent(typeof(Camera))]
public class ColorBlindr : MonoBehaviour
{
	public enum BlindnessType
	{
		Normal,
		Deuteranopia,
		Protanopia,
		Tritanopia
	}

	public BlindnessType Blindness;

	[Range(0.0f, 1.0f)]
	public float Strength = 1.0f;

	public Shader Shader;
	protected Material m_Material;

	public Material Material
	{
		get
		{
			if (m_Material == null)
			{
				m_Material = new Material(Shader);
				m_Material.hideFlags = HideFlags.HideAndDontSave;
			}

			return m_Material;
		}
	}

	public bool IsLinear
	{
		get { return QualitySettings.activeColorSpace == ColorSpace.Linear; }
	}

	void Start()
	{
		// Disable if we don't support image effects
		if (!SystemInfo.supportsImageEffects)
		{
			Debug.LogWarning("Image Effects are not supported on this platform.");
			enabled = false;
			return;
		}

		// Disable if we don't support render textures
		if (!SystemInfo.supportsRenderTextures)
		{
			Debug.LogWarning("RenderTextures are not supported on this platform.");
			enabled = false;
			return;
		}

		// Disable the image effect if the shader can't
		// run on the users graphics card
		if (Shader != null && !Shader.isSupported)
		{
			Debug.LogWarning("Missing or unsupported shader.");
			enabled = false;
			return;
		}
	}

	void OnDestroy()
	{
		if (m_Material)
			DestroyImmediate(m_Material);
	}

	void OnRenderImage(RenderTexture source, RenderTexture destination)
	{
		if (Shader == null || Blindness == BlindnessType.Normal)
		{
			Graphics.Blit(source, destination);
			return;
		}

		Material.SetFloat("_Strength", Strength);
		Graphics.Blit(source, destination, Material, ((int)Blindness - 1) + (IsLinear ? 3 : 0));
	}
}
