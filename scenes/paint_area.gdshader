shader_type canvas_item;

uniform sampler2D level_texture;
uniform sampler2D mask_texture; // This will come from our MaskViewport
uniform bool color_mode = false;
uniform vec4 solid_color : source_color;

void fragment() {
    // 1. Determine the source color
    vec4 output_color = color_mode ? solid_color : texture(level_texture, UV);

    // 2. Look at the mask texture to see if this pixel is "revealed"
    // The Line2D in the MaskViewport will be white (alpha 1.0)
    float mask_value = texture(mask_texture, UV).a;

    // 3. Apply the mask to the output alpha
    COLOR = vec4(output_color.rgb, output_color.a * mask_value);
}