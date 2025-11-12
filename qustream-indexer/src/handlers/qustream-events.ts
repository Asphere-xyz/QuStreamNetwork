import { EntityCache } from '../actions';
import { QuStreamRequest, QuStreamStats, RequestStatus } from '../model';
import * as quStreamAbi from '../abi/qustream-request-manager';

export class QuStreamEventsHandler {
  private cache: EntityCache;
  private contractAddress: string;

  constructor(cache: EntityCache, contractAddress: string) {
    this.cache = cache;
    this.contractAddress = contractAddress.toLowerCase();
  }

  async handleEthereumLog(event: any, block: any) {
    const address = event._evmLogAddress;
    const topics = event._evmLogTopics;

    if (!address || !topics || address.toLowerCase() !== this.contractAddress) {
      return;
    }

    // For Substrate/Moonbeam EVM events, the data is in event.args.log
    const eventArgs = event.args as any;
    const data = eventArgs?.log?.data || '0x';

    const log = {
      address: address,
      topics: topics,
      data: data,
    };

    const topic = topics[0];

    try {
      if (topic === quStreamAbi.topics.RequestRegistered) {
        await this.handleRequestRegistered(log, block);
      } else if (topic === quStreamAbi.topics.RequestStatusUpdated) {
        await this.handleRequestStatusUpdated(log, block);
      }
    } catch (error) {
      console.error(`Error handling EVM log at block ${block.header.height}:`, error);
    }
  }

  private async handleRequestRegistered(log: any, block: any) {
    const decoded = quStreamAbi.abi.decodeEventLog(quStreamAbi.events.RequestRegistered!, log.data, log.topics);

    const requestId = BigInt(decoded.id.toString());
    const sender = decoded.sender.toLowerCase();
    const userID = decoded.userID.toString();
    const qBlock = decoded.qBlock.toString();

    // Substrate block headers don't include timestamps, so we use the current time
    const timestamp = Date.now();

    const request = new QuStreamRequest({
      id: `${this.contractAddress}-${requestId}`,
      requestId,
      sender,
      userID,
      qBlock,
      status: RequestStatus.Pending,
      createdAtBlock: block.header.height,
      createdAtTimestamp: new Date(timestamp),
      processedAtBlock: null,
      processedAtTimestamp: null,
    });

    await this.cache.getStore().insert(request);

    await this.updateStats({
      totalRequests: 1,
      totalPending: 1,
      block,
    });

    console.log(`Request ${requestId} registered by ${sender} (userID: ${userID}, qBlock: ${qBlock})`);
  }

  private async handleRequestStatusUpdated(log: any, block: any) {
    const decoded = quStreamAbi.abi.decodeEventLog(quStreamAbi.events.RequestStatusUpdated!, log.data, log.topics);

    const requestId = BigInt(decoded.id.toString());
    const status = Number(decoded.status);

    const requestDbId = `${this.contractAddress}-${requestId}`;
    const request = await this.cache.getStore().get(QuStreamRequest, requestDbId);

    if (!request) {
      console.warn(`Request ${requestId} not found for status update`);
      return;
    }

    const timestamp = Date.now();

    const oldStatus = request.status;
    request.status = status === 1 ? RequestStatus.Success : RequestStatus.Fail;
    request.processedAtBlock = block.header.height;
    request.processedAtTimestamp = new Date(timestamp);

    await this.cache.getStore().save(request);

    const statsUpdate: any = {
      totalPending: oldStatus === RequestStatus.Pending ? -1 : 0,
      block,
    };

    if (request.status === RequestStatus.Success) {
      statsUpdate.totalSuccessful = 1;
    } else if (request.status === RequestStatus.Fail) {
      statsUpdate.totalFailed = 1;
    }

    await this.updateStats(statsUpdate);

    console.log(`Request ${requestId} status updated to ${RequestStatus[request.status]}`);
  }

  private async updateStats(updates: {
    totalRequests?: number;
    totalSuccessful?: number;
    totalFailed?: number;
    totalPending?: number;
    block: any;
  }) {
    const statsId = 'qustream-stats';
    let stats = await this.cache.getStore().get(QuStreamStats, statsId);

    if (!stats) {
      stats = new QuStreamStats({
        id: statsId,
        totalRequests: 0,
        totalSuccessful: 0,
        totalFailed: 0,
        totalPending: 0,
        lastUpdatedBlock: updates.block.header.height,
      });
    }

    stats.totalRequests += updates.totalRequests || 0;
    stats.totalSuccessful += updates.totalSuccessful || 0;
    stats.totalFailed += updates.totalFailed || 0;
    stats.totalPending += updates.totalPending || 0;
    stats.lastUpdatedBlock = updates.block.header.height;

    await this.cache.getStore().save(stats);
  }
}
