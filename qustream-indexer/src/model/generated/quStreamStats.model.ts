import {
  Entity as Entity_,
  Column as Column_,
  PrimaryColumn as PrimaryColumn_,
  IntColumn as IntColumn_,
  Index as Index_,
} from '@subsquid/typeorm-store';

@Entity_()
export class QuStreamStats {
  constructor(props?: Partial<QuStreamStats>) {
    Object.assign(this, props);
  }

  @PrimaryColumn_()
  id!: string;

  @IntColumn_({ nullable: false })
  totalRequests!: number;

  @IntColumn_({ nullable: false })
  totalSuccessful!: number;

  @IntColumn_({ nullable: false })
  totalFailed!: number;

  @IntColumn_({ nullable: false })
  totalPending!: number;

  @Index_()
  @IntColumn_({ nullable: false })
  lastUpdatedBlock!: number;
}
