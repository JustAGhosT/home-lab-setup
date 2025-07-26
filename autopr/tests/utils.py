from typing import TypeVar, Type
import asyncio

ActionT = TypeVar('ActionT')
InputsT = TypeVar('InputsT')

async def run_action_manually(action: Type[ActionT], inputs: InputsT):
    """Utility function to run an action manually for testing."""
    action_instance = action()
    return await action_instance.run(inputs)