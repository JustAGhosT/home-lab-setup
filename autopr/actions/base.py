from typing import TypeVar, Generic
from abc import ABC, abstractmethod

InputsT = TypeVar('InputsT')
OutputsT = TypeVar('OutputsT')

class Action(ABC, Generic[InputsT, OutputsT]):
    """Base class for all actions."""
    
    id: str
    
    @abstractmethod
    async def run(self, inputs: InputsT) -> OutputsT:
        """Run the action with the given inputs."""
        pass