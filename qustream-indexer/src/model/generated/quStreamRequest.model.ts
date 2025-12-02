import {
  Entity as Entity_,
  Column as Column_,
  PrimaryColumn as PrimaryColumn_,
  BigIntColumn as BigIntColumn_,
  Index as Index_,
  StringColumn as StringColumn_,
  IntColumn as IntColumn_,
  DateTimeColumn as DateTimeColumn_,
} from '@subsquid/typeorm-store';
import { RequestStatus } from './_requestStatus';

@Entity_()
export class QuStreamRequest {
  constructor(props?: Partial<QuStreamRequest>) {
    Object.assign(this, props);
  }

  @PrimaryColumn_()
  id!: string;

  @Index_()
  @BigIntColumn_({ nullable: false })
  requestId!: bigint;

  @Index_()
  @StringColumn_({ nullable: false })
  sender!: string;

  @StringColumn_({ nullable: false })
  userID!: string;

  @StringColumn_({ nullable: false })
  qBlock!: string;

  @Column_('varchar', { length: 7, nullable: false })
  status!: RequestStatus;

  @StringColumn_({ nullable: true })
  transactionHash!: string | undefined | null;

  @Index_()
  @IntColumn_({ nullable: false })
  createdAtBlock!: number;

  @DateTimeColumn_({ nullable: false })
  createdAtTimestamp!: Date;

  @IntColumn_({ nullable: true })
  processedAtBlock!: number | undefined | null;

  @DateTimeColumn_({ nullable: true })
  processedAtTimestamp!: Date | undefined | null;
}
