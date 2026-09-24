"""Drive one vehicle with CARLA's BasicAgent, in synchronous mode.

Run with: scripts/carla-python examples/basic_agent.py [--ticks N]
"""

import argparse

import carla
from agents.navigation.basic_agent import BasicAgent


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--host", default="localhost")
    parser.add_argument("--port", type=int, default=2000)
    parser.add_argument("--ticks", type=int, default=600, help="0 runs until the destination")
    args = parser.parse_args()

    client = carla.Client(args.host, args.port)
    client.set_timeout(30.0)
    world = client.get_world()

    original = world.get_settings()
    settings = world.get_settings()
    settings.synchronous_mode = True
    settings.fixed_delta_seconds = 0.05
    world.apply_settings(settings)

    vehicle = None
    try:
        spawns = world.get_map().get_spawn_points()
        blueprint = world.get_blueprint_library().find("vehicle.tesla.model3")
        vehicle = world.spawn_actor(blueprint, spawns[0])
        world.tick()

        agent = BasicAgent(vehicle, target_speed=30)
        destination = max(spawns, key=lambda s: s.location.distance(spawns[0].location))
        agent.set_destination(destination.location)
        print(f"driving {spawns[0].location} -> {destination.location}")

        spectator = world.get_spectator()
        tick = 0
        while not agent.done() and (args.ticks == 0 or tick < args.ticks):
            world.tick()
            vehicle.apply_control(agent.run_step())
            transform = vehicle.get_transform()
            spectator.set_transform(carla.Transform(
                transform.location - 8 * transform.get_forward_vector() + carla.Location(z=4),
                carla.Rotation(pitch=-15, yaw=transform.rotation.yaw)))
            if tick % 100 == 0:
                speed = 3.6 * vehicle.get_velocity().length()
                print(f"tick {tick:5d}  {speed:5.1f} km/h  {transform.location}")
            tick += 1

        print("arrived" if agent.done() else f"stopped after {tick} ticks")
    finally:
        world.apply_settings(original)
        if vehicle is not None:
            vehicle.destroy()


if __name__ == "__main__":
    main()
