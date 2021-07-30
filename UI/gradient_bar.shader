shader_type canvas_item;

uniform vec3 starting_color = vec3(0.14, 0.99, 0.21);
uniform vec3 ending_color = vec3(0.99, 0.11, 0.10);

uniform float progression = 0;
void fragment(){
	vec4 curr_color = texture(TEXTURE,UV);
    COLOR.rgb = curr_color.rgb * (starting_color + (ending_color - starting_color) * progression);
}