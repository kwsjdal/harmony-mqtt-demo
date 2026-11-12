import { MqttAsync, MqttMessage } from '@ohos/mqtt';

// ============================================================
// 配置参数
// ============================================================
const MQTT_BROKER = 'tcp://10.58.223.151:1883';  // Broker地址
const CLIENT_ID = 'HarmonyOS_APP_001';           // 客户端ID（需唯一）
const TOPIC = 'hi3861Test';                      // 人体感应实时状态
const QOS = 1;                                   // 服务质量等级

/**
 * 取手机本地时间（北京时间），格式 HH:MM:SS
 */
function nowTime(): string {
  const d = new Date();
  const hh = d.getHours().toString().padStart(2, '0');
  const mm = d.getMinutes().toString().padStart(2, '0');
  const ss = d.getSeconds().toString().padStart(2, '0');
  return `${hh}:${mm}:${ss}`;
}

@Entry
@Component
struct Index {

  @State motionState: string = '';       // '有人' 时才显示报警，无人时为空
  @State lastMotionTime: string = '--';  // 最近一次有人经过的时间
  @State motionCount: number = 0;        // 经过次数
  @State records: string[] = [];         // 经过记录（最新在前）
  @State connectionStatus: string = '未连接';
  private client = MqttAsync.createMqtt({
    url: MQTT_BROKER,
    clientId: CLIENT_ID,
    persistenceType: 1,
  });

  /**
   * 连接MQTT并订阅主题
   */
  async connectAndSubscribe() {
    try {
      await this.client.connect({
        cleanSession: true,
        connectTimeout: 30,
        keepAliveInterval: 60,
      });
      this.connectionStatus = '已连接';

      await this.client.subscribe({ topic: TOPIC, qos: QOS });

      this.client.messageArrived((err: Error, data: MqttMessage) => {
        if (err) {
          return;
        }
        try {
          const payload = JSON.parse(data.payload as string) as Record<string, Object>;

          if (payload.event === 'motion') {
            // ---- 有人经过：用 APP 本地时间（北京时间）记录到秒 ----
            const time = nowTime();
            this.motionState = '有人';
            this.lastMotionTime = time;
            this.motionCount++;
            this.records.unshift(time);   // 最新记录排在最上面
          } else if (payload.event === 'clear') {
            // ---- 人离开：报警消失 ----
            this.motionState = '';
          }
        } catch (e) {
          // 非JSON消息忽略
        }
      });
    } catch (err) {
      this.connectionStatus = '连接失败';
    }
  }

  /**
   * 清空本地经过记录
   */
  clearRecords() {
    this.records = [];
    this.motionCount = 0;
    this.lastMotionTime = '--';
  }

  /**
   * 断开连接
   */
  disconnect() {
    this.client.disconnect();
    this.connectionStatus = '未连接';
    this.motionState = '';
  }

  build() {
    Column() {
      Text('智能安防监控')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 10, bottom: 16 })

      // ===== 实时状态卡片 =====
      Column() {
        if (this.motionState === '有人') {
          Text('有人！')
            .fontSize(40)
            .fontWeight(FontWeight.Bold)
            .fontColor('#E91E63')
            .margin({ bottom: 14 })
        }

        Row() {
          Column() {
            Text('最近经过')
              .fontSize(13)
              .fontColor('#888')
            Text(this.lastMotionTime)
              .fontSize(30)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.motionState === '有人' ? '#E91E63' : '#333')
              .margin({ top: 4 })
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Center)

          Column() {
            Text('经过次数')
              .fontSize(13)
              .fontColor('#888')
            Text(`${this.motionCount}`)
              .fontSize(30)
              .fontWeight(FontWeight.Bold)
              .fontColor('#9C27B0')
              .margin({ top: 4 })
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Center)
        }
        .width('100%')
      }
      .width('100%')
      .padding({ top: 22, bottom: 22, left: 20, right: 20 })
      .backgroundColor(this.motionState === '有人' ? '#FCE4EC' : '#FFFFFF')
      .borderRadius(16)
      .shadow({ radius: 12, color: '#1A000000', offsetX: 0, offsetY: 4 })
      .margin({ bottom: 16 })

      // ===== 连接状态 =====
      Row() {
        Text('●')
          .fontSize(12)
          .fontColor(this.connectionStatus === '已连接' ? '#4CAF50' : '#F44336')
        Text(this.connectionStatus)
          .fontSize(14)
          .fontColor('#666')
          .margin({ left: 6 })
      }
      .margin({ bottom: 12 })

      // ===== 操作按钮 =====
      Row() {
        Button(this.connectionStatus === '已连接' ? '断开连接' : '连接设备')
          .onClick(() => {
            if (this.connectionStatus === '已连接') {
              this.disconnect();
            } else {
              this.connectAndSubscribe();
            }
          })
          .width(120)
          .borderRadius(20)
          .backgroundColor(this.connectionStatus === '已连接' ? '#F44336' : '#4CAF50')

        Button('清空')
          .onClick(() => {
            this.clearRecords();
          })
          .width(100)
          .borderRadius(20)
          .backgroundColor('#9E9E9E')
          .margin({ left: 12 })
      }
      .margin({ bottom: 16 })

      // ===== 经过记录列表 =====
      Row() {
        Text('经过记录')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor('#333')
        Blank()
        Text(`${this.records.length} 条`)
          .fontSize(13)
          .fontColor('#999')
      }
      .width('100%')
      .padding({ left: 4, right: 4, bottom: 8 })

      if (this.records.length === 0) {
        Column() {
          Text('暂无记录')
            .fontSize(14)
            .fontColor('#BBBBBB')
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        List() {
          ForEach(this.records, (time: string, index: number) => {
            ListItem() {
              Row() {
                Text('●')
                  .fontSize(10)
                  .fontColor('#E91E63')
                Text(time)
                  .fontSize(18)
                  .fontWeight(FontWeight.Medium)
                  .fontColor('#333')
                  .margin({ left: 10 })
                Blank()
                Text('有人经过')
                  .fontSize(13)
                  .fontColor('#999')
                Text('×')
                  .fontSize(20)
                  .fontColor('#BBBBBB')
                  .margin({ left: 12 })
                  .padding({ left: 8, right: 4 })
                  .onClick(() => {
                    // 删除该条记录
                    this.records.splice(index, 1);
                    if (this.motionCount > 0) {
                      this.motionCount--;
                    }
                  })
              }
              .width('100%')
              .padding({ top: 10, bottom: 10, left: 16, right: 12 })
              .backgroundColor('#FFFFFF')
              .borderRadius(10)
            }
            .margin({ bottom: 8 })
          }, (time: string, index: number) => `${index}-${time}`)
        }
        .width('100%')
        .layoutWeight(1)
      }
    }
    .padding({ left: 16, right: 16, bottom: 10 })
    .width('100%')
    .height('100%')
    .backgroundColor('#F7F8FA')
  }
}
