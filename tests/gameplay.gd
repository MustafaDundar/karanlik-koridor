extends SceneTree

var failures := 0

func check(ok: bool, message: String) -> void:
    if not ok:
        push_error(message)
        failures += 1
    else:
        print("PASS: ", message)

func _initialize() -> void:
    call_deferred("run")

func run() -> void:
    var scene = load("res://scenes/main.tscn").instantiate()
    root.add_child(scene)
    await physics_frame
    await physics_frame
    check(scene.player != null and scene.stalker != null, "Player and stalker spawn")
    check(scene.announcement.stream != null and scene.announcement.stream.get_length() > 1, "HF Turkish announcement imports")
    # Door frame must block both sides of the closed door.
    for x in [-1.7, 0.0, 1.7]:
        var ray := PhysicsRayQueryParameters3D.create(Vector3(x, 1, -46), Vector3(x, 1, -49))
        check(not scene.get_world_3d().direct_space_state.intersect_ray(ray).is_empty(), "Closed exit blocks x=%s" % x)
    scene.player.position = Vector3(0, 1, -46)
    Input.action_press("interact")
    scene._process(0.016)
    Input.action_release("interact")
    check(not scene.door_open, "Cannot open exit without fuse")
    await process_frame
    scene.player.position = Vector3(1.7, 1.1, -18)
    Input.action_press("interact")
    scene._process(0.016)
    Input.action_release("interact")
    check(scene.fuse_collected and not scene.fuse.visible, "Fuse pickup updates objective")
    await process_frame
    scene.player.position = Vector3(0, 1, -46)
    Input.action_press("interact")
    scene._process(0.016)
    Input.action_release("interact")
    check(scene.door_open and scene.door.collision_layer == 0, "Fuse opens exit collision")
    scene.player.position.z = -48
    scene._process(0.016)
    check(scene.completed and not scene.player.controls_enabled and not scene.stalker.active, "Win stops movement and chase")
    scene.reset_run()
    check(not scene.completed and not scene.door_open and not scene.fuse_collected, "Reset restores objective and exit")
    check(scene.player.battery == 100 and scene.player.velocity == Vector3.ZERO and scene.stalker.velocity == Vector3.ZERO, "Reset restores battery and velocities")
    scene.player.position.z = -25
    scene._process(0.016)
    check(scene.stalker.active and scene.stalker.position.z > scene.player.position.z, "Chase starts behind player")
    scene.stalker.position = scene.player.position
    scene._process(0.016)
    check(not scene.announcement_played and not scene.announcement.playing, "Reset stops and rearms announcement")
    check(not scene.scare_triggered and scene.player.position.z == 3, "Caught player returns to fresh run")
    print("GAMEPLAY TEST FAILURES: ", failures)
    scene.set_process(false)
    scene.announcement.stop()
    await create_timer(0.15).timeout
    scene.queue_free()
    await process_frame
    quit(1 if failures else 0)
