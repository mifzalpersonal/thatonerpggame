shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx, depth_prepass_alpha;

// PENTING: Untuk AnimatedSprite3D/Sprite3D, biarkan Godot menyuntikkan 
// tekstur animasinya lewat keyword texture_albedo bawaan.
uniform sampler2D texture_albedo : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D noise_texture; 

uniform float burn_progress : hint_range(0.0, 1.0) = 0.0;
uniform vec4 burn_color : source_color = vec4(1.0, 0.35, 0.0, 1.0);
uniform vec4 body_modulate : source_color = vec4(1.0, 1.0, 1.0, 1.0);

void fragment() {
	// Membaca UV dan Albedo langsung dari frame AnimatedSprite3D yang sedang aktif
	vec4 albedo_tex = texture(texture_albedo, UV);
	
	// Jika pixel aslinya transparan (luar border sprite), langsung buang agar tidak jadi kotak putih/hitam
	if (albedo_tex.a < 0.1) {
		discard;
	}

	float noise_value = texture(noise_texture, UV).r;
	float dist_from_center = distance(UV, vec2(0.5, 0.5));
	float burn_mask = dist_from_center + (noise_value * 0.3);

	float fire_border = smoothstep(burn_progress + 0.08, burn_progress, burn_mask);

	vec3 final_color = albedo_tex.rgb * body_modulate.rgb;
	final_color = mix(final_color, burn_color.rgb * 5.0, fire_border * step(0.01, burn_progress));

	ALBEDO = final_color;
	ALPHA = albedo_tex.a;
	
	EMISSION = burn_color.rgb * fire_border * 6.0 * step(0.01, burn_progress);
}