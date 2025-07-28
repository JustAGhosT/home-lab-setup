from typing import TypeVar, Type, Any
import asyncio

InputsT = TypeVar('InputsT')

async def run_action_manually(action: Type[Any], inputs: InputsT) -> Any:
    """Utility function to run an action manually for testing."""
    action_instance = action()
    return await action_instance.run(inputs)  # type: ignore[attr-defined]