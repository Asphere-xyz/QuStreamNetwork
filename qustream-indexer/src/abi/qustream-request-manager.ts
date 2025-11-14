import * as ethers from 'ethers';

export const ABI = [
  'event RequestRegistered(uint256 indexed id, address indexed sender, string userID, string qBlock)',
  'event RequestStatusUpdated(uint256 indexed id, uint8 status)',
];

export const abi = new ethers.Interface(ABI);

export interface RequestRegisteredEvent {
  id: bigint;
  sender: string;
  userID: string;
  qBlock: string;
}

export interface RequestStatusUpdatedEvent {
  id: bigint;
  status: number;
}

export const events = {
  RequestRegistered: abi.getEvent('RequestRegistered'),
  RequestStatusUpdated: abi.getEvent('RequestStatusUpdated'),
};

export const topics = {
  RequestRegistered: abi.getEvent('RequestRegistered')!.topicHash,
  RequestStatusUpdated: abi.getEvent('RequestStatusUpdated')!.topicHash,
};
