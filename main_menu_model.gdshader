shader_type spatial;

// PERBAIKAN UTAMA: Kita pakai diffuse_lambert_wrap biar cahaya matahari sorenya 
// bisa "membungkus" kedua sisi Plane rumput secara halus tanpa bikin hitam pekat.
render_mode blend_mix, depth_draw_opaque, cull_disabled, diffuse_lambert_wrap, specular_schlick_ggx;

uniform sampler2D texture_albedo : source_color, filter_nearest_mipmap;
uniform float kecepatan_angin = 2.5;
uniform float kekuatan_angin = 0.15;

void vertex() {
	float faktor_atas = 1.0 - UV.y;
	VERTEX.x += sin(TIME * kecepatan_angin + VERTEX.y * 2.0) * kekuatan_angin * faktor_atas;
	VERTEX.z += cos(TIME * (kecepatan_angin * 0.8) + VERTEX.x) * (kekuatan_angin * 0.6) * faktor_atas;
}

void fragment() {
	vec4 albedo_tex = texture(texture_albedo, UV);
	ALBEDO = albedo_tex.rgb;
	ALPHA = albedo_tex.a;
	
	// Kita hapus kode NORMAL yang merusak lampu kemarin.
	// Kita kunci roughness dan specular-nya di sini biar gak silau plastik.
	ROUGHNESS = 1.0;              
	SPECULAR = 0.0;               
}