extends Node

func go_to_level(level_scene: PackedScene) -> void:

    if (level_scene != null):
        LoadingScreen.transition()
        await LoadingScreen.on_transition_finished
        get_tree().change_scene_to_packed(level_scene)
