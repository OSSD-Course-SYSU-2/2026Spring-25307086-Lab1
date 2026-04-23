import { promptAction, curves } from '@kit.ArkUI';

interface Shop {
  name: string;
  type: string;
  level: string;
  score: number;
  busyLevel: number;
  avgCost: number;
  history: number[];
}

const defaultShops: Shop[] = [
  { name: '松濤園焗飯', type: '吃食堂', level: '夯', score: 5, busyLevel: 2, avgCost: 15, history: [10, 15] },
  { name: '南門口潮汕牛肉', type: '出去吃', level: '夯', score: 5, busyLevel: 3, avgCost: 95, history: [30, 45] },
  { name: '新港西路麥當勞', type: '出去吃', level: '人上人', score: 3, busyLevel: 1, avgCost: 35, history: [5, 8] },
  { name: '瑞幸咖啡', type: '點外賣', level: '夯', score: 5, busyLevel: 2, avgCost: 16, history: [10, 12] },
  { name: '白象大骨麵', type: '吃泡面', level: '人上人', score: 3, busyLevel: 1, avgCost: 5, history: [3] }
];

PersistentStorage.persistProp('MyShopsData', JSON.stringify(defaultShops));

@Entry
@Component
struct Index {
  @State resultText: string = '今天吃什麼？';
  @State resultSubText: string = '時空與環境感知算法已啟動';
  @State resultCategory: string = '';
  @State isRolling: boolean = false;

  // 環境與偏好狀態
  @State currentPreference: number = 0;
  @State isRainy: boolean = false;
  @State isBudgetExpanded: boolean = false;
  @State currentBudget: number = 100;

  @State predictedWaitTime: number = 0;
  @State showReroll: boolean = false;
  @State lastWaitTimeRecord: number = 999;

  @State textScale: number = 1.0;
  @State isShowSheet: boolean = false;
  @State editingIndex: number = -1;

  // 批量錄入與表單狀態
  @State batchInputText: string = '';
  @State inputName: string = '';
  @State inputType: string = '吃食堂';
  @State inputBusyLevel: number = 2;
  @State inputCost: string = '20';
  private levels: string[] = ['拉完了', 'NPC', '人上人', '頂級', '夯'];
  @State selectedLevelIndex: number = 4;

  @StorageLink('MyShopsData') shopsJson: string = '';
  @State shops: Shop[] = [];

  aboutToAppear() {
    try { this.shops = JSON.parse(this.shopsJson); }
    catch (e) { this.shops = defaultShops; }
  }

  syncDataToStorage() {
    this.shopsJson = JSON.stringify(this.shops);
  }

  predictWaitTime(shop: Shop): number {
    if (shop.type === '吃泡面') return Math.floor(Math.random() * 3) + 3;

    if (shop.type === '點外賣') {
      let baseTime = Math.floor(Math.random() * 25) + 25;
      return this.isRainy ? baseTime + 20 : baseTime;
    }

    const history = shop.history || [10, 15];
    const avg = history.reduce((a, b) => a + b, 0) / history.length;
    const now = new Date();
    const hour = now.getHours();

    let timeFactor = 1.0;
    if (hour >= 15 && hour < 17) timeFactor = 0.3;
    else if (hour >= 11 && hour <= 13 || hour >= 18 && hour <= 19) timeFactor = 1.8;

    const busyFactorMap = [0.8, 1.2, 2.2];
    const busyFactor = busyFactorMap[(shop.busyLevel || 2) - 1];

    return Math.ceil(avg * busyFactor * timeFactor);
  }

  rollFood() {
    if (this.isRolling) return;
    this.lastWaitTimeRecord = this.showReroll ? this.predictedWaitTime : 999;
    this.isRolling = true;
    this.showReroll = false;
    this.resultCategory = '';

    let count = 0;
    let intervalId = setInterval(() => {
      let types = ['吃食堂', '點外賣', '出去吃', '吃泡面'];
      this.resultText = types[Math.floor(Math.random() * types.length)];
      count++;
      if (count > 15) {
        clearInterval(intervalId);
        this.finishRolling();
      }
    }, 80);
  }

  finishRolling() {
    let finalType = this.resultText;

    let weatherFactor = 1.0;
    if (this.isRainy && finalType === '出去吃') weatherFactor = 0.2;
    if (this.isRainy && (finalType === '點外賣' || finalType === '吃泡面')) weatherFactor = 2.0;

    let availableShops = this.shops.filter(s => {
      let isTypeMatch = s.type === finalType;
      let isBudgetMatch = this.isBudgetExpanded ? s.avgCost <= this.currentBudget : true;
      return isTypeMatch && isBudgetMatch;
    });

    if (availableShops.length > 0) {
      let weightPool: Shop[] = [];
      availableShops.forEach(shop => {
        let finalWeight = 1;
        let waitTime = this.predictWaitTime(shop);

        switch (this.currentPreference) {
          case 0: finalWeight = Math.max(1, (shop.score || 3) - ((shop.busyLevel || 2) - 1)); break;
          case 1: finalWeight = Math.max(1, 10 - Math.floor(shop.avgCost / 10)); break;
          case 2: finalWeight = waitTime < 10 ? 10 : Math.max(1, 4 - Math.floor(waitTime / 5)); break;
          case 3: finalWeight = (shop.score || 3) >= 4 ? shop.score * 3 : 1; break;
        }

        let finalCount = Math.ceil(finalWeight * weatherFactor);
        for (let i = 0; i < finalCount; i++) { weightPool.push(shop); }
      });

      let pickedShop = weightPool.length > 0 ? weightPool[Math.floor(Math.random() * weightPool.length)] : availableShops[0];
      this.resultText = pickedShop.name;
      this.resultCategory = `🏷️ ${finalType}`;
      this.resultSubText = `預估人均：￥${pickedShop.avgCost} | 評價：${pickedShop.level}`;

      let newWaitTime = this.predictWaitTime(pickedShop);
      this.predictedWaitTime = this.lastWaitTimeRecord < 999 ? Math.min(newWaitTime, this.lastWaitTimeRecord) : newWaitTime;
      if (this.predictedWaitTime > 25) this.showReroll = true;
    } else {
      this.resultSubText = `當前條件下無 [${finalType}] 記錄`;
    }

    this.isRolling = false;
    animateTo({ curve: curves.springMotion() }, () => { this.textScale = 1.2; });
    setTimeout(() => { animateTo({ curve: curves.springMotion() }, () => { this.textScale = 1.0; }); }, 500);
  }

  parseBatchInput() {
    if (this.batchInputText.trim() === '') return;
    let lines = this.batchInputText.split('\n');
    let addedCount = 0;
    lines.forEach(line => {
      let parts = line.split(/[ ,，-]+/);
      if (parts.length >= 2) {
        let name = parts[0];
        let type = parts[1];
        let cost = parts.length >= 3 ? Number(parts[2]) : 20;
        const newShop: Shop = {
          name: name, type: type, level: '人上人', score: 3,
          busyLevel: 2, avgCost: isNaN(cost) ? 20 : cost, history: [15]
        };
        this.shops.push(newShop);
        addedCount++;
      }
    });
    this.syncDataToStorage();
    this.batchInputText = '';
    promptAction.showToast({ message: `成功導入 ${addedCount} 家店鋪` });
  }

  @Builder SheetBuilder() {
    Tabs() {
      TabContent() {
        Column({ space: 15 }) {
          Text('智能批量導入').fontSize(18).fontWeight(FontWeight.Bold).width('100%')
          TextArea({ placeholder: '格式示例：\n松濤園 吃食堂 15\n麥當勞 出去吃 35', text: this.batchInputText })
            .onChange(v => this.batchInputText = v).height(150).backgroundColor('#F5F7FA')
          Button('解析並存入飯單').width('100%').height(45).backgroundColor('#1A1A1A')
            .onClick(() => this.parseBatchInput())
          Text('支持多行粘貼，自動識別空格或逗號分隔符').fontSize(12).fontColor('#999').width('100%')
        }.padding(25)
      }.tabBar('批量導入')

      TabContent() {
        Column({ space: 15 }) {
          Text(this.editingIndex === -1 ? '手動錄入' : '重新評價').fontSize(18).fontWeight(FontWeight.Bold)
          TextInput({ placeholder: '店鋪名稱', text: this.inputName }).onChange(v => this.inputName = v)
          Row({ space: 10 }) {
            TextInput({ placeholder: '人均消費', text: this.inputCost }).type(InputType.Number).layoutWeight(1).onChange(v => this.inputCost = v)
            Select([{ value: '吃食堂' }, { value: '點外賣' }, { value: '出去吃' }, { value: '吃泡面' }])
              .value(this.inputType).onSelect((i, v) => this.inputType = v).layoutWeight(1)
          }
          Button('保存修改').width('100%').height(45).backgroundColor('#1A1A1A')
            .onClick(() => {
              if (!this.inputName) return;
              const newShop: Shop = {
                name: this.inputName, type: this.inputType, level: this.levels[this.selectedLevelIndex],
                score: this.selectedLevelIndex + 1, busyLevel: this.inputBusyLevel,
                avgCost: Number(this.inputCost), history: [15]
              };
              if (this.editingIndex === -1) this.shops.push(newShop);
              else this.shops[this.editingIndex] = newShop;
              this.syncDataToStorage();
              this.isShowSheet = false;
            })
        }.padding(25)
      }.tabBar('手動錄入')
    }.backgroundColor(Color.White).borderRadius({ topLeft: 20, topRight: 20 })
  }

  @Builder DeleteButton(index: number) {
    Button('刪除').backgroundColor('#D32F2F').fontColor(Color.White).width(80).height('100%')
      .onClick(() => { this.shops.splice(index, 1); this.syncDataToStorage(); })
  }

  build() {
    Column() {
      Column({ space: 12 }) {
        Text(this.resultText).fontSize(34).fontWeight(FontWeight.Bolder).scale({ x: this.textScale, y: this.textScale })

        if (this.resultCategory !== '') {
          Text(this.resultCategory).fontSize(12).fontColor('#007DFF').backgroundColor('rgba(0, 125, 255, 0.1)')
            .padding({ left: 10, right: 10, top: 4, bottom: 4 }).borderRadius(8)
        }

        Text(this.resultSubText).fontSize(14).fontColor('#666')

        // 💡 這裡修復了 Toggle 的寫法
        Row({ space: 15 }) {
          Text('當前天氣：').fontSize(14).fontColor('#333')
          Toggle({ type: ToggleType.Button, isOn: this.isRainy }) {
            Text(this.isRainy ? '正在下雨' : '天氣晴朗')
              .fontSize(12)
              .fontColor(this.isRainy ? Color.White : '#333')
              .padding(8)
          }
          .selectedColor('#1A1A1A')
          .onChange(v => this.isRainy = v)
        }.margin({ top: 5 })

        Row({ space: 8 }) {
          ForEach(['綜合', '省錢', '效率', '美味'], (label: string, index: number) => {
            Button(label).layoutWeight(1).height(35).fontSize(12)
              .backgroundColor(this.currentPreference === index ? '#1A1A1A' : 'rgba(0,0,0,0.06)')
              .fontColor(this.currentPreference === index ? Color.White : '#333')
              .onClick(() => this.currentPreference = index)
          })
        }.width('100%').padding({ left: 10, right: 10 })

        Column({ space: 5 }) {
          Text(this.isBudgetExpanded ? '收起預算設置 ▲' : '展開預算設置 ▼')
            .fontSize(12).fontColor('#666').onClick(() => { animateTo({ duration: 300, curve: Curve.EaseInOut }, () => { this.isBudgetExpanded = !this.isBudgetExpanded; }); })

          if (this.isBudgetExpanded) {
            Row() {
              Text('預算上限：').fontSize(14)
              Text(`￥${this.currentBudget}`).fontSize(18).fontWeight(FontWeight.Bold).fontColor('#E64A19')
            }.margin({ top: 10 })
            Slider({ value: this.currentBudget, min: 10, max: 200, step: 5 }).onChange(v => this.currentBudget = v).width('85%').selectedColor('#E64A19')
          }
        }.padding(10).backgroundColor('rgba(255,255,255,0.4)').borderRadius(15)

        if (this.predictedWaitTime > 0) {
          Text(`預計排隊：${this.predictedWaitTime} 分鐘`).fontColor(this.predictedWaitTime > 25 ? '#D32F2F' : '#388E3C').fontWeight(FontWeight.Bold)
          if (this.showReroll) Button('重新選擇').height(30).backgroundColor('#D32F2F').onClick(() => this.rollFood())
        }

        Button(this.isRolling ? '算法計算中...' : '開始決定').width('75%').height(50).backgroundColor('#1A1A1A').onClick(() => this.rollFood())
      }
      .padding({ top: 50, bottom: 25, left: 15, right: 15 }).width('100%')
      .backgroundColor('rgba(255, 255, 255, 0.4)').backgroundBlurStyle(BlurStyle.Thin).borderRadius({ bottomLeft: 40, bottomRight: 40 })

      Row() {
        Text(`江湖飯單 (${this.shops.length})`).fontWeight(FontWeight.Bold).layoutWeight(1)
        Button('添加/導入').height(30).fontSize(12).backgroundColor('#007DFF').onClick(() => { this.editingIndex = -1; this.isShowSheet = true; })
      }.width('100%').padding(20)

      List({ space: 10 }) {
        ForEach(this.shops, (item: Shop, index: number) => {
          ListItem() {
            Row() {
              Column() {
                Text(item.name).fontWeight(FontWeight.Bold)
                Text(`人均 ￥${item.avgCost}`).fontSize(12).fontColor('#666')
              }.alignItems(HorizontalAlign.Start).layoutWeight(1)
              Text(item.level).fontSize(11).fontColor(Color.White).backgroundColor('#1A1A1A').padding({ left: 6, right: 6, top: 2, bottom: 2 }).borderRadius(5)
            }
            .width('100%').padding(15).backgroundColor(Color.White).borderRadius(12)
            .onClick(() => { this.editingIndex = index; this.isShowSheet = true; })
          }.swipeAction({ end: this.DeleteButton(index) })
        })
      }.padding({ left: 20, right: 20, bottom: 10 }).layoutWeight(1)
    }
    .width('100%').height('100%')
    .linearGradient({ direction: GradientDirection.RightBottom, colors: [['#E0EAFC', 0], ['#CFDEF3', 1]] })
    .bindSheet($$this.isShowSheet, this.SheetBuilder(), { height: SheetSize.MEDIUM })
  }
}