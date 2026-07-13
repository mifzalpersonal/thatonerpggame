shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx, depth_prepass_alpha;

// Kita pakai HINT_SCREEN_TEXTURE atau langsung pakai tekstur standar 3D
uniform sampler2D albedo_texture : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D noise_texture; 

// --- PARAMETER ANIMATION TWEEN ---
uniform float effect_progress : hint_range(0.0, 1.0) = 0.0;
uniform vec4 effect_glow_color : source_color = vec4(1.0, 0.35, 0.0, 1.0); 

// --- PARAMETER WARNA STATUS ---
uniform vec4 body_modulate : source_color = vec4(1.0, 1.0, 1.0, 1.0); 

void fragment() {
	// Membaca tekstur yang terpasang di material secara aman
	vec4 albedo_tex = texture(albedo_texture, UV);
	
	// Jika pixel transparan, buang
	if (albedo_tex.a < 0.1) {
		discard;
	}

	float noise_value = texture(noise_texture, UV).r;
	float dist_from_center = distance(UV, vec2(0.5, 0.5));
	float mask = dist_from_center + (noise_value * 0.2);

	// Logika kilatan lingkaran
	float edge_border = smoothstep(effect_progress - 0.15, effect_progress, mask) * smoothstep(effect_progress + 0.15, effect_progress, mask);

	vec3 final_color = albedo_tex.rgb * body_modulate.rgb;
	
	if (effect_progress > 0.01) {
		final_color = mix(final_color, effect_glow_color.rgb * 4.0, edge_border);
	}

	ALBEDO = final_color;
	ALPHA = albedo_tex.a;
	EMISSION = effect_glow_color.rgb * edge_border * 5.0 * step(0.01, effect_progress);
}