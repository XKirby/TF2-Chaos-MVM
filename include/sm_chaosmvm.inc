/**
 * Used to set an Attribute value in a custom ability plugin.
 *
 * @param client		A client to get the effect value to.
 * @param effect		An effect plugin.
 * @param effname		The name of the effect your're looking for.
 * @param value			Anything to set the value to.
 * @noreturn
 */
//forward SetAttribValue(client, Handle:effect, String:effname[128], value);

/**
 * Used to get an Attribute value in a custom ability plugin.
 *
 * @param client		A client to get the effect value to.
 * @param effect		An effect plugin.
 * @param effname		The name of the effect your're looking for.
 * @return			The value of the effect.
 */
//forward any:GetAttribValue(client, Handle:effect, String:effname[128]);

/**
 * Used inside of a custom ability plugin to set the value from within the plugin.
 *
 * @param client		A client to get the effect value to.
 * @param effect		An effect plugin.
 * @param effname		The name of the effect your're looking for.
 * @param value			Anything to set the value to.
 * @noreturn
 */
native CMVM_SetAttribValue(client, Handle:effect, String:effname[128], value);

/**
 * Used inside of a custom ability plugin to get the value from within the plugin.
 *
 * @param client		A client to get the effect value to.
 * @param effect		An effect plugin.
 * @param effname		The name of the effect your're looking for.
 * @return			The value of the effect.
 */
native any:CMVM_GetAttribValue(client, Handle:effect, String:effname[128]);